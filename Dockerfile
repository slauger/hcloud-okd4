FROM docker.io/hashicorp/terraform:1.17.1@sha256:a5d5a5a892c98f60fcbfa81eac2a40fc19e7b3fa7719bccae10ff6111d22524a AS terraform
FROM docker.io/hashicorp/packer:1.16.2@sha256:5aa2160b623fad0b99f8ae8d9cc162ba9775ae428367edca88addc01bb86dd52 AS packer
FROM docker.io/alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

LABEL maintainer="simon@lauger.name" \
      org.opencontainers.image.source="https://github.com/slauger/hcloud-okd4" \
      org.opencontainers.image.description="Toolbox to deploy OKD and OpenShift on Hetzner Cloud" \
      org.opencontainers.image.licenses="MIT"

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
      python3

# External tools
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=packer /bin/packer /usr/local/bin/packer

# Install the Packer plugins pinned in packer/plugins.pkr.hcl
COPY packer/plugins.pkr.hcl /tmp/packer/plugins.pkr.hcl
RUN packer init /tmp/packer && rm -rf /tmp/packer

WORKDIR /workspace
