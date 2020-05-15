FROM docker.io/hashicorp/terraform:0.12.25@sha256:682b18382a542d031086133c9f2cddc45f2d3bc287d709c7cff75e6aa847d6f7 AS terraform
FROM docker.io/hashicorp/packer:1.5.6@sha256:013754a8f5f8916dbf225192a8c0f2a55bb7b8851e45138c9f00a4bfaaa955b5 AS packer
FROM docker.io/alpine:3.11@sha256:39eda93d15866957feaee28f8fc5adb545276a64147445c64992ef69804dbf01

LABEL maintainer="simon@lauger.name"

ARG OPENSHIFT_RELEASE

RUN apk update && \
    apk add \
      bash \
      ca-certificates \
      openssh-client \
      openssl \
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
