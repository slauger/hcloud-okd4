FROM docker.io/hashicorp/terraform:0.12.18@sha256:aac4f7c61e8bd04c1ca14681b099cb8434788881bbe08febe5b7f9c0d2eabf1c AS terraform
FROM hashicorp/packer:1.5.1@sha256:20f3f783025f293f44f44c8eb6ca0f6a1809b76e1836d64444de3b4300ccd97b AS packer
FROM docker.io/alpine:3.11@sha256:d371657a4f661a854ff050898003f4cb6c7f36d968a943c1d5cde0952bd93c80

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
