FROM docker.io/hashicorp/terraform:1.15.6@sha256:adae45661e45d3c88beef071ee1277b4621cea73517aae7f0844657c8e85f641 AS terraform
FROM docker.io/hashicorp/packer:1.15.4@sha256:8be72877859e00e13124b26373f0505b2a2597c5393ecbea900be28b4be58186 AS packer
FROM docker.io/alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

LABEL maintainer="simon@lauger.name"

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

ARG DEPLOYMENT_TYPE
ENV DEPLOYMENT_TYPE=${DEPLOYMENT_TYPE}

RUN apk update && \
    apk add \
      bash \
      ca-certificates \
      openssh-client \
      openssl \
      ansible \
      make \
      rsync \
      curl \
      git \
      jq \
      libc6-compat \
      apache2-utils \
      python3 \
      py3-pip \
      libvirt-client

# OpenShift Installer
COPY openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz .
COPY openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz .

RUN tar vxzf openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz openshift-install && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz oc && \
    tar vxzf openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz kubectl && \
    mv openshift-install /usr/local/bin/openshift-install && \
    mv oc /usr/local/bin/oc && \
    mv kubectl /usr/local/bin/kubectl && \
    rm openshift-install-linux-${OPENSHIFT_RELEASE}.tar.gz && \
    rm openshift-client-linux-${OPENSHIFT_RELEASE}.tar.gz

# External tools
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=packer /bin/packer /usr/local/bin/packer

# Install Packer Plugin
RUN packer plugins install github.com/hashicorp/hcloud

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
