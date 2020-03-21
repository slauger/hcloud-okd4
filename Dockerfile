FROM docker.io/hashicorp/terraform:0.12.23@sha256:aeda61416d71f2022deb8b83b334eac716a65a20b6b940b87f22515904129dd3 AS terraform
FROM hashicorp/packer:1.5.4@sha256:df7feeff930b04a42f2027dd0924392246f7b5a38f0c56531a2d14cd0d1e9408 AS packer
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
      curl \
      make \
      libc6-compat \
      apache2-utils

RUN curl -sfLO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar vxzf oc.tar.gz && \
    mv oc /usr/local/bin/oc && \
    oc adm release extract --command=openshift-install registry.svc.ci.openshift.org/origin/release:${OPENSHIFT_RELEASE} && \
    oc adm release extract --command=oc registry.svc.ci.openshift.org/origin/release:${OPENSHIFT_RELEASE} && \
    mv openshift-install /usr/local/bin/openshift-install && \
    mv oc /usr/local/bin/oc

# External tools
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=packer /bin/packer /usr/local/bin/packer

# Create workspace
RUN mkdir /workspace
WORKDIR /workspace
