.DEFAULT_GOAL := build

# ocp
OPENSHIFT_MIRROR?=https://mirror.openshift.com/pub/openshift-v4
OCP_RELEASE_CHANNEL?=stable-4.22

# okd
OKD_MIRROR?=https://github.com/okd-project/okd/releases/download
# optional version prefix to pin latest_version to a stream (e.g. 4.22)
OKD_RELEASE_STREAM?=

# either okd or ocp
DEPLOYMENT_TYPE?=okd

# release version, required for fetch and all targets using the openshift binaries
OPENSHIFT_RELEASE?=

# openshift binaries of the selected release, downloaded by make fetch
BIN_DIR=downloads/$(DEPLOYMENT_TYPE)/$(OPENSHIFT_RELEASE)
OPENSHIFT_INSTALL=$(BIN_DIR)/openshift-install
OC=$(BIN_DIR)/oc

# toolbox image (version independent)
CONTAINER_NAME?=quay.io/slauger/hcloud-okd4
CONTAINER_TAG?=latest

# coreos
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
	@curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/okd-project/okd/releases?per_page=100" | jq -j -r '[.[] | select(.prerelease == false and .draft == false) | .tag_name | select(startswith("$(OKD_RELEASE_STREAM)"))][0]'

.PHONY: latest_version_ocp
latest_version_ocp:
	@curl -s https://raw.githubusercontent.com/openshift/cincinnati-graph-data/master/channels/$(OCP_RELEASE_CHANNEL).yaml | egrep '(4\.[0-9]+\.[0-9]+)' | tail -n1 | cut -d" " -f2

# fetch the openshift binaries of a release into downloads/<type>/<version>
.PHONY: fetch
fetch: fetch_$(DEPLOYMENT_TYPE)

fetch_okd: RELEASE_URL=$(OKD_MIRROR)/$(OPENSHIFT_RELEASE)
fetch_ocp: RELEASE_URL=$(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)

.PHONY: fetch_okd fetch_ocp
fetch_okd fetch_ocp:
	@if [ -z "$(OPENSHIFT_RELEASE)" ]; then echo "ERROR: OPENSHIFT_RELEASE is not set"; exit 1; fi
	@if [ -x "$(OPENSHIFT_INSTALL)" ] && [ -x "$(OC)" ]; then \
		echo "$(BIN_DIR) already contains the binaries"; \
	else \
		mkdir -p $(BIN_DIR) && \
		echo "downloading openshift-install $(OPENSHIFT_RELEASE)" && \
		curl -fsSL $(RELEASE_URL)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz | tar -xz -C $(BIN_DIR) openshift-install && \
		echo "downloading openshift-client $(OPENSHIFT_RELEASE)" && \
		curl -fsSL $(RELEASE_URL)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz | tar -xz -C $(BIN_DIR) oc kubectl; \
	fi

# fail early if the binaries of the selected release are missing
.PHONY: check_release
check_release:
	@if [ -z "$(OPENSHIFT_RELEASE)" ]; then echo "ERROR: OPENSHIFT_RELEASE is not set"; exit 1; fi
	@if [ ! -x "$(OPENSHIFT_INSTALL)" ]; then echo "ERROR: $(OPENSHIFT_INSTALL) not found, run make fetch first"; exit 1; fi

.PHONY: build
build:
	docker build -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

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
		-e DEPLOYMENT_TYPE=$(DEPLOYMENT_TYPE) -e OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) \
		-e PATH=/workspace/$(BIN_DIR):/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
		$(CONTAINER_NAME):$(CONTAINER_TAG) /bin/bash

.PHONY: generate_manifests
generate_manifests: check_release
	mkdir config
	cp install-config.yaml config/install-config.yaml
	$(OPENSHIFT_INSTALL) create manifests --dir=config
	cp manifests/*.yml config/manifests/

.PHONY: generate_ignition
generate_ignition: check_release
	rsync -av config/ ignition
	$(OPENSHIFT_INSTALL) create ignition-configs --dir=ignition

.PHONY: hcloud_image
hcloud_image: check_release
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	if [ "$(DEPLOYMENT_TYPE)" == "okd" ]; then (cd packer && packer build -var "first_boot_kargs=$(FIRST_BOOT_KARGS)" -var fcos_url=$(shell $(OPENSHIFT_INSTALL) coreos print-stream-json | jq -r '.architectures.x86_64.artifacts.qemu.formats."qcow2.gz".disk.location') hcloud-fcos.json); fi
	if [ "$(DEPLOYMENT_TYPE)" == "ocp" ]; then (cd packer && packer build -var "first_boot_kargs=$(FIRST_BOOT_KARGS)" -var rhcos_url=$(shell $(OPENSHIFT_INSTALL) coreos print-stream-json | jq -r '.architectures.x86_64.artifacts.qemu.formats."qcow2.gz".disk.location') hcloud-rhcos.json); fi

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
	(cd terraform && terraform init && terraform $(MODE) -var image=$(COREOS_IMAGE) -var bootstrap=$(BOOTSTRAP))
	if [ "$(BOOTSTRAP)" == "false" ] && [ "$(MODE)" == "apply" ] && [ -f terraform/bootstrap.auto.tfvars ]; then $(MAKE) delete_ignition; fi

.PHONY: destroy
destroy:
	(cd terraform && terraform init && terraform destroy)
