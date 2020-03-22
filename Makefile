.DEFAULT_GOAL := toolbox

OPENSHIFT_RELEASE=4.4.0-0.okd-2020-03-21-112849
FCOS_STREAM=stable
FCOS_RELEASE=31.20200223.3.0

CONTAINER_NAME=openshift-toolbox
CONTAINER_TAG=$(OPENSHIFT_RELEASE)

BOOTSTRAP=false

print_version:
	@echo $(OPENSHIFT_RELEASE)

build: toolbox

toolbox:
	docker build --build-arg OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -t $(CONTAINER_NAME):$(CONTAINER_TAG) .

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
	cd packer && packer build -var fcos_stream=$(FCOS_STREAM) -var fcos_release=$(FCOS_RELEASE) hcloud-fcos.json

hcloud_boostrap_image:
	cd packer && packer build -var fcos_stream=$(FCOS_STREAM) -var fcos_release=$(FCOS_RELEASE) -var snapshot_prefix=fcos-boostrap -var ignition_config=../ignition/bootstrap.ign -var image_type=bootstrap hcloud-fcos.json

sign_csr:
	test -f ignition/auth/kubeconfig
	bash -c "export KUBECONFIG=$(shell pwd)/ignition/auth/kubeconfig; oc get csr --no-headers | awk '{print $1}' | xargs oc adm certificate approve"

wait_bootstrap:
	openshift-install --dir=config/ wait-for bootstrap-complete --log-level=debug

wait_completion:
	openshift-install --dir=config/ wait-for install-complete --log-level=debug

infrastructure:
	cd terraform && terraform init && terraform apply -var bootstrap=$(BOOTSTRAP)
