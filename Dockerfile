FROM docker.io/hashicorp/terraform:0.14.2@sha256:fb74c7a3a4b21e1a4044174413872e4225dfe85c287174c00b4a6bc66382d5fe AS terraform
FROM docker.io/hashicorp/packer:1.6.6@sha256:523457b5371562c4d9c21621ee85c71c31e7ff53d5ec303a5daf07c55531b84e AS packer
FROM docker.io/alpine/helm:3.4.2@sha256:298397182125f0772a0802fc658031893b4e249e7a524a2e3b3a662a842dfad9 AS helm
FROM docker.io/alpine:3.12@sha256:25f5332d060da2c7ea2c8a85d2eac623bd0b5f97d508b165f846c7d172897438

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
