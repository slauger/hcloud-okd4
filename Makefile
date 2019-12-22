.DEFAULT_GOAL := toolbox

OPENSHIFT_RELEASE=4.3.0-0.okd-2019-11-15-182656
FCOS_STREAM=testing
FCOS_RELEASE=31.20191211.1
CONTAINER_NAME=openshift-toolbox:$(OPENSHIFT_RELEASE)

print_version:
	@echo $(OPENSHIFT_RELEASE)

fetch:
	wget -O openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	wget -O openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz https://github.com/openshift/okd/releases/download/$(OPENSHIFT_RELEASE)/openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz

clean:
	rm openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz || true
	rm openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz || true

toolbox:
	test -f openshift-install-linux-$(OPENSHIFT_RELEASE).tar.gz
	test -f openshift-client-linux-$(OPENSHIFT_RELEASE).tar.gz
	docker build --build-arg OPENSHIFT_RELEASE=$(OPENSHIFT_RELEASE) -t $(CONTAINER_NAME) .

run:
	docker run -it -v $(PWD):/workspace $(CONTAINER_NAME) /bin/bash

manifests:
	mkdir config
	cp install-config.yaml config/install-config.yaml
	openshift-install create manifests --dir=config

ignition:
	mkdir ignition
	cp install-config.yaml ignition/install-config.yaml
	openshift-install create ignition-configs --dir=ignition

hcloud_image:
	cd packer && packer build -var fcos_stream=$(FCOS_STREAM) -var fcos_release=$(FCOS_RELEASE) -var snapshot_name=hetzner-fcos-$(FCOS_STREAM)-$(FCOS_RELEASE) hetzner-fcos.json

infrastructure_bootstrap:
	cd terraform && \
	terraform init && \
	terraform apply -var bootstrap=true

sign_csr:
	KUBECONFIG=ignition/auth/kubeconfig
	bash -c "oc get csr --no-headers | awk '{print $1}' | xargs oc adm certificate approve"

wait_bootstrap:
	openshift-install --dir=config/ wait-for bootstrap-complete --log-level=debug

wait_completion:
	openshift-install --dir=config/ wait-for install-complete --log-level=debug

infrastructure:
	cd terraform && \
	terraform init &&
	terraform apply
