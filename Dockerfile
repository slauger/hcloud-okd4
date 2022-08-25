FROM docker.io/hashicorp/terraform:1.2.8@sha256:565711ffe74a11fb260eb499389e7a4b6a18343a6e916edd00ed108a80ca2258 AS terraform
FROM docker.io/hashicorp/packer:1.8.3@sha256:ac62cbd11b86a43d5efef0e27432ebea282b15a621e8e0e2ade1e1f856400fec AS packer
FROM docker.io/alpine:3.16.2@sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad

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
