.DEFAULT_GOAL := build

OPENSHIFT_RELEASE=4.4.0-0.okd-2020-03-28-092308
FCOS_STREAM=stable
FCOS_RELEASE=31.20200310.3.0

CONTAINER_NAME=docker.io/cmon2k/openshift-toolbox
CONTAINER_TAG=$(OPENSHIFT_RELEASE)

BOOTSTRAP=false

print_version:
	@echo $(OPENSHIFT_RELEASE)

check_prereq_envs:
	@if [ -z "$(TF_VAR_dns_domain)" ]; then echo "ERROR: TF_VAR_dns_domain is not set"; exit 1; fi
	@if [ -z "$(TF_VAR_dns_zone_id)" ]; then echo "ERROR: TF_VAR_dns_zone_id is not set"; exit 1; fi
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	@if [ -z "$(CLOUDFLARE_EMAIL)" ]; then echo "ERROR: CLOUDFLARE_EMAIL is not set"; exit 1; fi
	@if [ -z "$(CLOUDFLARE_API_KEY)" ]; then echo "ERROR: CLOUDFLARE_API_KEY is not set"; exit 1; fi

fetch:
	wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

build:
	docker build --build-arg OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

test:
	docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(shell pwd):/src:ro gcr.io/gcp-runtimes/container-structure-test:latest test --image $(CONTAINER_NAME):$(CONTAINER_TAG) --config /src/tests/image.tests.yaml

push:
	docker push $(CONTAINER_NAME):$(CONTAINER_TAG)

run:
	docker run -it -v $(PWD):/workspace $(CONTAINER_NAME):$(CONTAINER_TAG) /bin/bash

manifests:
	mkdir config
	cp install-config.yaml config/install-config.yaml
	openshift-install create manifests --dir=config

ignition:
	mkdir ignition
	cp install-config.yaml ignition/install-config.yaml
	openshift-install create ignition-configs --dir=ignition

hcloud_image:
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	cd packer && packer build -var fcos_stream=$(FCOS_STREAM) -var fcos_release=$(FCOS_RELEASE) hcloud-fcos.json

hcloud_boostrap_image:
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	cd packer && packer build -var fcos_stream=$(FCOS_STREAM) -var fcos_release=$(FCOS_RELEASE) -var snapshot_prefix=fcos-boostrap -var ignition_config=../ignition/bootstrap.ign -var image_type=bootstrap hcloud-fcos.json

sign_csr:
	@if [ ! -f "ignition/auth/kubeconfig" ]; then echo "ERROR: ignition/auth/kubeconfig not found"; exit 1; fi
	bash -c "export KUBECONFIG=$(KUBECONFIG); oc get csr -o name | xargs oc adm certificate approve || true"

wait_bootstrap:
	openshift-install --dir=config/ wait-for bootstrap-complete --log-level=debug

wait_completion:
	openshift-install --dir=config/ wait-for install-complete --log-level=debug

infrastructure:
	@if [ -z "$(TF_VAR_dns_domain)" ]; then echo "ERROR: TF_VAR_dns_domain is not set"; exit 1; fi
	@if [ -z "$(TF_VAR_dns_zone_id)" ]; then echo "ERROR: TF_VAR_dns_zone_id is not set"; exit 1; fi
	@if [ -z "$(HCLOUD_TOKEN)" ]; then echo "ERROR: HCLOUD_TOKEN is not set"; exit 1; fi
	@if [ -z "$(CLOUDFLARE_EMAIL)" ]; then echo "ERROR: CLOUDFLARE_EMAIL is not set"; exit 1; fi
	@if [ -z "$(CLOUDFLARE_API_KEY)" ]; then echo "ERROR: CLOUDFLARE_API_KEY is not set"; exit 1; fi
	cd terraform && terraform init && terraform apply -var bootstrap=$(BOOTSTRAP)
