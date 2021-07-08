FROM docker.io/hashicorp/terraform:1.0.2@sha256:613b1f8779ed9942f0a5573d2e6a640b20a9e21abbce03803cdfb9c5976b32c7 AS terraform
FROM docker.io/hashicorp/packer:1.7.3@sha256:173008fe1d4cfada9a5fe7e641128ca87dd1e595534afc9abd3b2683b1491fd4 AS packer
FROM docker.io/alpine:3.14.0@sha256:234cb88d3020898631af0ccbbcca9a66ae7306ecd30c9720690858c1b007d2a0

LABEL maintainer="simon@lauger.name"

ARG OPENSHIFT_RELEASE
ENV OPENSHIFT_RELEASE=${OPENSHIFT_RELEASE}

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

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
