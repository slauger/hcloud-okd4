FROM docker.io/hashicorp/terraform:1.17.0@sha256:4d1b496a256f2989bccdb04b9104a4ede97234b10fba90259e173e905ec4fb58 AS terraform
FROM docker.io/hashicorp/packer:1.16.1@sha256:9fd66d5a4ea0598036e6b50ac6f8c0e72c27746648a5abe480463119e9486ea7 AS packer
FROM docker.io/alpine:3.24.3@sha256:1b7232cda4ca3dc20b5d1247bdc9bfb631f2661d15d323bdd6fccc035ed1a9e7

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
