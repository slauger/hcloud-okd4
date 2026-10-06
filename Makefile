.DEFAULT_GOAL := build

# the recipes rely on bash (e.g. "==" in tests), /bin/sh is dash on Debian/Ubuntu
SHELL := /bin/bash

# ocp
OPENSHIFT_MIRROR?=https://mirror.openshift.com/pub/openshift-v4
OCP_RELEASE_CHANNEL?=stable-4.22

# okd
OKD_MIRROR?=https://github.com/okd-project/okd/releases/download
# optional version prefix to pin latest_version to a stream (e.g. 4.22)
OKD_RELEASE_STREAM?=

# either okd or ocp
DEPLOYMENT_TYPE?=okd

# architecture of the toolbox and the openshift binaries, defaults to the host
HOST_ARCH:=$(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
TOOLBOX_ARCH?=$(HOST_ARCH)
ifeq ($(TOOLBOX_ARCH),arm64)
	BIN_SUFFIX=-arm64
else
	BIN_SUFFIX=
endif

# cluster architecture: amd64, or arm64 on Hetzner CAX servers (OCP only, OKD
# does not publish arm64 release payloads)
ARCH?=amd64
ifeq ($(ARCH),amd64)
	STREAM_ARCH=x86_64
	HCLOUD_ARCH=x86
	PACKER_SERVER_TYPE?=cpx32
else ifeq ($(ARCH),arm64)
	STREAM_ARCH=aarch64
	HCLOUD_ARCH=arm
	PACKER_SERVER_TYPE?=cax31
else
  $(error ARCH must be amd64 or arm64)
endif
ifeq ($(DEPLOYMENT_TYPE)-$(ARCH),okd-arm64)
  $(error OKD does not publish arm64 release payloads, ARCH=arm64 requires DEPLOYMENT_TYPE=ocp)
endif

# The openshift binaries of both architectures install amd64 clusters, so arm64
# clusters (OCP) use the aarch64 release payload explicitly.
ifeq ($(ARCH),arm64)
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE?=quay.io/openshift-release-dev/ocp-release:$(OPENSHIFT_RELEASE)-$(STREAM_ARCH)
endif

# release version, required for fetch and all targets using the openshift binaries
OPENSHIFT_RELEASE?=

# openshift binaries of the selected release, downloaded by make fetch
BIN_DIR=downloads/$(DEPLOYMENT_TYPE)/$(OPENSHIFT_RELEASE)/$(TOOLBOX_ARCH)
OPENSHIFT_INSTALL=$(BIN_DIR)/openshift-install
OC=$(BIN_DIR)/oc

# sha256sum is not available on all macOS versions, shasum reads the same format
SHA256SUM:=$(shell command -v sha256sum >/dev/null 2>&1 && echo sha256sum || echo "shasum -a 256")

# toolbox image (version independent)
CONTAINER_NAME?=ghcr.io/slauger/hcloud-okd4
CONTAINER_TAG?=latest

# coreos
COREOS_DISK=.architectures.$(STREAM_ARCH).artifacts.qemu.formats."qcow2.gz".disk
COREOS_RELEASE=.architectures.$(STREAM_ARCH).artifacts.qemu.release
coreos_stream=$$($(CURDIR)/$(OPENSHIFT_INSTALL) coreos print-stream-json | jq -r '$(1)')
# CoreOS release of OPENSHIFT_RELEASE, empty if its binaries are not downloaded
coreos_image_release=$$(if [ -x "$(CURDIR)/$(OPENSHIFT_INSTALL)" ]; then $(CURDIR)/$(OPENSHIFT_INSTALL) coreos print-stream-json | jq -r '$(COREOS_RELEASE)'; fi)

ifeq ($(DEPLOYMENT_TYPE),ocp)
	COREOS_IMAGE=rhcos
else ifeq ($(DEPLOYMENT_TYPE),okd)
	COREOS_IMAGE=fcos
else
	$(error installer only supports ocp or okd)
endif

# s3 bucket (hetzner object storage) for the bootstrap ignition config
S3_BUCKET?=
S3_LOCATION?=nbg1
S3_ENDPOINT?=https://$(S3_LOCATION).your-objectstorage.com
S3_PRESIGN_EXPIRY?=86400
S3_OBJECT=$(shell jq -r .infraID ignition/metadata.json 2>/dev/null)/bootstrap.ign
AWS_CLI=aws --endpoint-url $(S3_ENDPOINT) --region $(S3_LOCATION)

# resolvers used by the nodes, also during the first boot (baked into the image)
NAMESERVERS?=1.1.1.1 1.0.0.1
FIRST_BOOT_KARGS=rd.neednet=1 ip=dhcp $(foreach ns,$(NAMESERVERS),nameserver=$(ns))

# dns provider: cloudflare or none (bring your own DNS)
TF_VAR_dns_provider?=cloudflare
export TF_VAR_dns_provider

# terraform switches
BOOTSTRAP?=false
MODE?=apply

# openshift version
.PHONY: latest_version
latest_version: latest_version_$(DEPLOYMENT_TYPE)

.PHONY: latest_version_okd
latest_version_okd:
	@curl -sSf -H "Accept: application/vnd.github.v3+json" $(if $(GITHUB_TOKEN),-H "Authorization: Bearer $(GITHUB_TOKEN)") "https://api.github.com/repos/okd-project/okd/releases?per_page=100" | jq -e -j -r --arg stream "$(OKD_RELEASE_STREAM)" '[.[] | select(.prerelease == false and .draft == false) | .tag_name | select($$stream == "" or startswith($$stream + "."))][0]'

.PHONY: latest_version_ocp
latest_version_ocp:
	@curl -s https://raw.githubusercontent.com/openshift/cincinnati-graph-data/master/channels/$(OCP_RELEASE_CHANNEL).yaml | grep -E '(4\.[0-9]+\.[0-9]+)' | tail -n1 | cut -d" " -f2

# fetch the openshift binaries of a release into downloads/<type>/<version>/<toolbox arch>
.PHONY: fetch
fetch: fetch_$(DEPLOYMENT_TYPE)

fetch_okd: RELEASE_URL=$(OKD_MIRROR)/$(OPENSHIFT_RELEASE)
fetch_ocp: RELEASE_URL=$(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)

# The tarballs are verified against the sha256sum.txt of the release before
# anything is extracted, both mirrors publish one.
FETCH_INSTALL_TGZ=openshift-install-linux$(BIN_SUFFIX)-$(OPENSHIFT_RELEASE).tar.gz
FETCH_CLIENT_TGZ=openshift-client-linux$(BIN_SUFFIX)-$(OPENSHIFT_RELEASE).tar.gz
FETCH_TMP=$(BIN_DIR)/.download

.PHONY: fetch_okd fetch_ocp
fetch_okd fetch_ocp:
	@if [ -z "$(OPENSHIFT_RELEASE)" ]; then echo "ERROR: OPENSHIFT_RELEASE is not set"; exit 1; fi
	@if [ -x "$(OPENSHIFT_INSTALL)" ] && [ -x "$(OC)" ] && [ -x "$(BIN_DIR)/kubectl" ]; then \
		echo "$(BIN_DIR) already contains the binaries"; \
	else \
		set -e; \
		rm -rf $(FETCH_TMP) && mkdir -p $(FETCH_TMP); \
		echo "downloading openshift-install and openshift-client $(OPENSHIFT_RELEASE) ($(TOOLBOX_ARCH))"; \
		curl -fsSL -o $(FETCH_TMP)/sha256sum.txt $(RELEASE_URL)/sha256sum.txt; \
		curl -fsSL -o $(FETCH_TMP)/$(FETCH_INSTALL_TGZ) $(RELEASE_URL)/$(FETCH_INSTALL_TGZ); \
		curl -fsSL -o $(FETCH_TMP)/$(FETCH_CLIENT_TGZ) $(RELEASE_URL)/$(FETCH_CLIENT_TGZ); \
		awk -v a=$(FETCH_INSTALL_TGZ) -v b=$(FETCH_CLIENT_TGZ) '$$2 == a || $$2 == b' $(FETCH_TMP)/sha256sum.txt > $(FETCH_TMP)/checksums; \
		if [ "$$(wc -l < $(FETCH_TMP)/checksums)" -ne 2 ]; then echo "ERROR: checksums of the tarballs not found in sha256sum.txt"; exit 1; fi; \
		(cd $(FETCH_TMP) && $(SHA256SUM) -c checksums); \
		tar -xzf $(FETCH_TMP)/$(FETCH_INSTALL_TGZ) -C $(BIN_DIR) openshift-install; \
		tar -xzf $(FETCH_TMP)/$(FETCH_CLIENT_TGZ) -C $(BIN_DIR) oc kubectl; \
		rm -rf $(FETCH_TMP); \
	fi

# fail early if the binaries of the selected release are missing
.PHONY: check_release
check_release:
	@if [ -z "$(OPENSHIFT_RELEASE)" ]; then echo "ERROR: OPENSHIFT_RELEASE is not set"; exit 1; fi
	@if [ ! -x "$(OPENSHIFT_INSTALL)" ]; then echo "ERROR: $(OPENSHIFT_INSTALL) not found, run make fetch first"; exit 1; fi

.PHONY: build
build:
	docker build --platform linux/$(TOOLBOX_ARCH) -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

.PHONY: test
test:
	docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(shell pwd):/src:ro gcr.io/gcp-runtimes/container-structure-test:latest test --image $(CONTAINER_NAME):$(CONTAINER_TAG) --config /src/tests/image.tests.yaml

.PHONY: push
push:
	docker push $(CONTAINER_NAME):$(CONTAINER_TAG)

.PHONY: run
run:
	docker run -it --hostname openshift-toolbox \
		--mount type=bind,source="$(shell pwd)",target=/workspace \
		--mount type=bind,source="$(HOME)/.ssh,target=/root/.ssh" \
		--platform linux/$(TOOLBOX_ARCH) \
		-e DEPLOYMENT_TYPE=$(DEPLOYMENT_TYPE) -e OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -e ARCH=$(ARCH) \
		-e PATH=/workspace/$(BIN_DIR):/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
		$(CONTAINER_NAME):$(CONTAINER_TAG) /bin/bash

.PHONY: generate_manifests
generate_manifests: check_release
	@if [ -d config ]; then echo "ERROR: config/ already exists, remove it to generate new manifests"; exit 1; fi
	mkdir config
	cp install-config.yaml config/install-config.yaml
	$(OPENSHIFT_INSTALL) create manifests --dir=config
	cp manifests/*.yml config/manifests/

.PHONY: generate_ignition
generate_ignition: check_release
	rsync -av config/ ignition
	$(OPENSHIFT_INSTALL) create ignition-configs --dir=ignition

# A snapshot of the same CoreOS release is reused, REBUILD=true builds a new one.
.PHONY: hcloud_image
hcloud_image: check_release
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	@release=$(call coreos_stream,$(COREOS_RELEASE)); \
	snapshot=$$(curl -fsS -G -H "Authorization: Bearer $$HCLOUD_TOKEN" https://api.hetzner.cloud/v1/images \
		--data-urlencode type=snapshot --data-urlencode status=available --data-urlencode architecture=$(HCLOUD_ARCH) \
		--data-urlencode "label_selector=os=$(COREOS_IMAGE),image_type=generic,$(COREOS_IMAGE)_release=$$release" | jq -r '.images[0].id // empty'); \
	if [ -n "$$snapshot" ] && [ "$(REBUILD)" != "true" ]; then \
		echo "snapshot $$snapshot already contains $(COREOS_IMAGE) $$release ($(HCLOUD_ARCH)), set REBUILD=true to build a new one"; \
		exit 0; \
	fi; \
	echo "building $(COREOS_IMAGE) $$release ($(HCLOUD_ARCH)) snapshot"; \
	cd packer && packer build \
		-var "first_boot_kargs=$(FIRST_BOOT_KARGS)" \
		-var server_type=$(PACKER_SERVER_TYPE) \
		-var architecture=$(HCLOUD_ARCH) \
		-var "$(COREOS_IMAGE)_url=$(call coreos_stream,$(COREOS_DISK).location)" \
		-var "$(COREOS_IMAGE)_sha256=$(call coreos_stream,$(COREOS_DISK)."uncompressed-sha256")" \
		-var "$(COREOS_IMAGE)_stream=$(call coreos_stream,.stream)" \
		-var "$(COREOS_IMAGE)_release=$$release" \
		hcloud-$(COREOS_IMAGE).json

.PHONY: sign_csr
sign_csr: check_release
	@if [ ! -f "ignition/auth/kubeconfig" ]; then echo "ERROR: ignition/auth/kubeconfig not found"; exit 1; fi
	bash -c "export KUBECONFIG=$(shell pwd)/ignition/auth/kubeconfig; $(OC) get csr -o name | xargs $(OC) adm certificate approve || true"

.PHONY: wait_bootstrap
wait_bootstrap: check_release
	$(OPENSHIFT_INSTALL) --dir=ignition/ wait-for bootstrap-complete --log-level=debug

.PHONY: wait_completion
wait_completion: check_release
	$(OPENSHIFT_INSTALL) --dir=ignition/ wait-for install-complete --log-level=debug

.PHONY: upload_ignition
upload_ignition:
	@if [ -z "$(S3_BUCKET)" ]; then echo "ERROR: S3_BUCKET is not set"; exit 1; fi
	@if [ -z "$(AWS_ACCESS_KEY_ID)" ] || [ -z "$(AWS_SECRET_ACCESS_KEY)" ]; then echo "ERROR: AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY is not set"; exit 1; fi
	@if [ ! -f "ignition/bootstrap.ign" ]; then echo "ERROR: ignition/bootstrap.ign not found"; exit 1; fi
	$(AWS_CLI) s3 cp ignition/bootstrap.ign s3://$(S3_BUCKET)/$(S3_OBJECT) --content-type application/vnd.coreos.ignition+json
	@echo "bootstrap_ignition_url = \"$$($(AWS_CLI) s3 presign s3://$(S3_BUCKET)/$(S3_OBJECT) --expires-in $(S3_PRESIGN_EXPIRY))\"" > terraform/bootstrap.auto.tfvars
	@echo "pre-signed URL written to terraform/bootstrap.auto.tfvars"

.PHONY: delete_ignition
delete_ignition:
	@if [ -z "$(S3_BUCKET)" ]; then echo "ERROR: S3_BUCKET is not set"; exit 1; fi
	$(AWS_CLI) s3 rm s3://$(S3_BUCKET)/$(S3_OBJECT)
	rm -f terraform/bootstrap.auto.tfvars

.PHONY: infrastructure
infrastructure:
	@if [ -z "$(TF_VAR_dns_domain)" ]; then echo "ERROR: TF_VAR_dns_domain is not set"; exit 1; fi
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	@if [ "$(TF_VAR_dns_provider)" == "cloudflare" ] && [ -z "$(TF_VAR_dns_zone_id)" ]; then echo "ERROR: TF_VAR_dns_zone_id is not set"; exit 1; fi
	@if [ "$(TF_VAR_dns_provider)" == "cloudflare" ] && [ -z "$(CLOUDFLARE_EMAIL)" ]; then echo "ERROR: CLOUDFLARE_EMAIL is not set"; exit 1; fi
	if [ "$(BOOTSTRAP)" == "true" ] && [ "$(MODE)" == "apply" ]; then $(MAKE) upload_ignition; fi
	(cd terraform && terraform init && terraform $(MODE) -var image=$(COREOS_IMAGE) -var "image_release=$(coreos_image_release)" -var architecture=$(HCLOUD_ARCH) -var bootstrap=$(BOOTSTRAP))
	if [ "$(BOOTSTRAP)" == "false" ] && [ "$(MODE)" == "apply" ] && [ -f terraform/bootstrap.auto.tfvars ]; then $(MAKE) delete_ignition; fi

.PHONY: destroy
destroy:
	(cd terraform && terraform init && terraform destroy -var image=$(COREOS_IMAGE) -var architecture=$(HCLOUD_ARCH))
	if [ -f terraform/bootstrap.auto.tfvars ]; then $(MAKE) delete_ignition; fi
