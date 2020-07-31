.DEFAULT_GOAL := build

OPENSHIFT_MIRROR=https://mirror.openshift.com/pub/openshift-v4

OKD_RELEASE=4.5.0-0.okd-2020-07-29-070316
FCOS_STREAM=stable
FCOS_RELEASE=32.20200715.3.0

OCP_RELEASE=4.5.4
RHCOS_RELEASE=4.5.2
RHCOS_RELEASE_MINOR=$(shell echo $(RHCOS_RELEASE) | egrep -o 4\.[0-9]+)

CONTAINER_NAME=docker.io/cmon2k/openshift-toolbox
CONTAINER_TAG=$(OPENSHIFT_RELEASE)

DEPLOYMENT_TYPE=okd
BOOTSTRAP=false
MODE=apply

ifeq ($(DEPLOYMENT_TYPE),ocp)
  OPENSHIFT_RELEASE=$(OCP_RELEASE)
  COREOS_IMAGE=rhcos
  COREOS_RELEASE=$(RHCOS_RELEASE)
else ifeq ($(DEPLOYMENT_TYPE),okd)
  OPENSHIFT_RELEASE=$(OKD_RELEASE)
  COREOS_IMAGE=fcos
  COREOS_RELEASE=$(FCOS_RELEASE)
else
  $(error installer only supports ocp or okd)
endif

print_version:
	@echo $(OPENSHIFT_RELEASE)

fetch: fetch_$(DEPLOYMENT_TYPE)

fetch_okd:
	wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

fetch_ocp:
	wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz $(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz $(OPENSHIFT_MIRROR)/clients/ocp/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

build:
	docker build --build-arg OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

test:
	docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(shell pwd):/src:ro gcr.io/gcp-runtimes/container-structure-test:latest test --image $(CONTAINER_NAME):$(CONTAINER_TAG) --config /src/tests/image.tests.yaml

push:
	docker push $(CONTAINER_NAME):$(CONTAINER_TAG)

run:
	docker run -it --hostname openshift-toolbox --mount type=bind,source="$(shell pwd)",target=/workspace --mount type=bind,source="$(HOME)/.ssh,target=/root/.ssh" $(CONTAINER_NAME):$(CONTAINER_TAG) /bin/bash

generate_manifests:
	mkdir config
	cp install-config.yaml config/install-config.yaml
	openshift-install create manifests --dir=config

generate_ignition:
	rsync -av config/ ignition
	openshift-install create ignition-configs --dir=ignition

hcloud_image:
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	if [ "$(DEPLOYMENT_TYPE)" == "okd" ]; then (cd packer && packer build -var fcos_stream=$(FCOS_STREAM) -var fcos_release=$(FCOS_RELEASE) hcloud-fcos.json); fi
	if [ "$(DEPLOYMENT_TYPE)" == "ocp" ]; then (cd packer && packer build -var rhcos_release=$(RHCOS_RELEASE) -var rhcos_release_minor=$(RHCOS_RELEASE_MINOR) hcloud-rhcos.json); fi

sign_csr:
	@if [ ! -f "ignition/auth/kubeconfig" ]; then echo "ERROR: ignition/auth/kubeconfig not found"; exit 1; fi
	bash -c "export KUBECONFIG=$(shell pwd)/ignition/auth/kubeconfig; oc get csr -o name | xargs oc adm certificate approve || true"

wait_bootstrap:
	openshift-install --dir=ignition/ wait-for bootstrap-complete --log-level=debug

wait_completion:
	openshift-install --dir=ignition/ wait-for install-complete --log-level=debug

infrastructure:
	@if [ -z "$(TF_VAR_dns_domain)" ]; then echo "ERROR: TF_VAR_dns_domain is not set"; exit 1; fi
	@if [ -z "$(TF_VAR_dns_zone_id)" ]; then echo "ERROR: TF_VAR_dns_zone_id is not set"; exit 1; fi
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	@if [ -z "$(CLOUDFLARE_EMAIL)" ]; then echo "ERROR: CLOUDFLARE_EMAIL is not set"; exit 1; fi
	(cd terraform && terraform init && terraform $(MODE) -var image=$(COREOS_IMAGE) -var bootstrap=$(BOOTSTRAP))
	if [ "$(MODE)" == "apply" ]; then (cd ansible && ansible-playbook site.yml); fi

destroy:
	(cd terraform && terraform init && terraform destroy)
