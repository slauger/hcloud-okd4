# okd4-hetzner

Deploy OKD4 (OpenShift) Hetzner Cloud with Hashicorp Packer and Terraform.

Example code for Terraform follows as soon as possible.

## Current version

- OpenShift Release: 4.3.0-0.okd-2019-11-15-182656
- Fedora CoreOS Stream: testing
- Fedora CoreOS Release: 31.20191211.1

## Usage

### Build toolbox

```
make fetch
make toolbox
```

### Run toolbox

```
make run
```

### Create your install-config.yaml

```
---
apiVersion: v1
baseDomain: 'example.com'
metadata:
  name: 'okd4'
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
  machineCIDR:
platform:
  none: {}
pullSecret: '{"auths":{"none":{"auth": "none"}}}'
sshKey: ssh-rsa AABBCC... Some_Service_User
```

### Create cluster manifests

```
make manifests
```

### Create ignition config

```
make ignition
```

### Create Fedora CoreOS image

Build a Fedora CoreOS hcloud image and embed the hcloud user data source (`http://169.254.169.254/hetzner/v1/userdata`).

Because the Fedora CoreOS image will be stored in RAM during the build, at least a cx31 instance is required.

Be sure that your hcloud token is set via env `HCLOUD_TOKEN`.

```
make hcloud_image
```

### Build infrastructure with Terraform

Be sure that your hcloud token is set via env `HCLOUD_TOKEN`.

Cloudflare credentials must be set via env `CLOUDFLARE_EMAIL` and `CLOUDFLARE_TOKEN`.

```
make infrastructure BOOSTRAP=true
```

### Wait for the bootstrap to complete

```
make wait_bootstrap
```

### Sign all CSRs

```
make sign_csr
```

### Finish the installation process

```
make wait_completion
```

### Cleanup bootstrap node

Be sure that your hcloud token is set via env `HCLOUD_TOKEN`.

Cloudflare credentials must be set via env `CLOUDFLARE_EMAIL` and `CLOUDFLARE_TOKEN`.

```
make infrastructure
```

## Author

- [slauger](https://github.com/slauger)
