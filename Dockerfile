FROM docker.io/hashicorp/terraform:0.13.4@sha256:6d1f9f5d2ca2fe2570d3e72c3bc88248f90820cc052d37c43fecec295ee4ce30 AS terraform
FROM docker.io/hashicorp/packer:1.6.4@sha256:9de774eebc434af0f04f6d0a7e3bed7b25549b983e1d59b803b461be417fe277 AS packer
FROM docker.io/alpine/helm:3.4.1@sha256:6ca8d4fe131d60035f75750a770478d7398578335effb7df61ffd11d46a9467a AS helm
FROM docker.io/alpine:3.12@sha256:d7342993700f8cd7aba8496c2d0e57be0666e80b4c441925fc6f9361fa81d10e

LABEL maintainer="simon@lauger.name"

ARG OPENSHIFT_RELEASE

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
      libc6-compat \
      apache2-utils \
      python3 \
      py3-pip

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
COPY --from=helm /usr/bin/helm /usr/local/bin/helm

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
