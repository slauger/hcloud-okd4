FROM docker.io/hashicorp/terraform:1.16.5@sha256:c7926feace05d0f7e73542842bf3945924e955a1f782cf000ccbb8d18fa42d77 AS terraform
FROM docker.io/hashicorp/packer:1.16.1@sha256:9fd66d5a4ea0598036e6b50ac6f8c0e72c27746648a5abe480463119e9486ea7 AS packer
FROM docker.io/alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

LABEL maintainer="simon@lauger.name"

# Version independent toolbox, the openshift binaries are downloaded per
# release into downloads/<type>/<version> of the workspace (make fetch).
RUN apk add --no-cache \
      bash \
      ca-certificates \
      openssh-client \
      openssl \
      aws-cli \
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

# External tools
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=packer /bin/packer /usr/local/bin/packer

# Install Packer Plugin
RUN packer plugins install github.com/hashicorp/hcloud

WORKDIR /workspace
