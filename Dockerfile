FROM docker.io/hashicorp/terraform:0.12.20@sha256:5e19b9bab0b6d079cae8822be22cd7010f65177356600154b77fc4fc81bdde31 AS terraform
FROM hashicorp/packer:1.5.4@sha256:d9b49a2a86379a98a9dd11a89246b601449e57f46a4b21419c1e485e502f603a AS packer
FROM docker.io/alpine:3.11@sha256:ddba4d27a7ffc3f86dd6c2f92041af252a1f23a8e742c90e6e1297bfa1bc0c45

LABEL maintainer="simon@lauger.name"

ARG OPENSHIFT_RELEASE

RUN apk update && \
    apk add \
      bash \
      git \
      vim \
      ca-certificates \
      openssh-client \
      sudo \
      bind-tools \
      openssl \
      vim \
      rsync \
      make \
      libc6-compat \
      apache2-utils

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
