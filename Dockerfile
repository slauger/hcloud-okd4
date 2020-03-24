FROM docker.io/hashicorp/terraform:0.12.24@sha256:53fb1c0a78c8bb91c4a855c1b352ea7928f6fa65f8080dc7a845e240dd2a9bee AS terraform
FROM docker.io/hashicorp/packer:1.5.4@sha256:df7feeff930b04a42f2027dd0924392246f7b5a38f0c56531a2d14cd0d1e9408 AS packer
FROM docker.io/alpine:3.11@sha256:cb8a924afdf0229ef7515d9e5b3024e23b3eb03ddbba287f4a19c6ac90b8d221

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
