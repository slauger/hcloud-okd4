![Docker Build](https://github.com/slauger/hcloud-okd4/workflows/Docker%20Image%20CI/badge.svg)

# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud with Cloudflare Loadbalancing using Hashicorp Packer and Terraform.

## Current status

Current CI builds of OKD 4.4 seem to get stuck in the bootstrap process.

```
openshift-install --dir=config/ wait-for bootstrap-complete --log-level=debug
DEBUG OpenShift Installer 4.4.0-0.okd-2020-03-21-112849
DEBUG Built from commit fc790034704d5e279eabacd833d3e90c76815978
INFO Waiting up to 20m0s for the Kubernetes API at https://api.ocp4.example.com:6443...
INFO API v1.17.1 up
INFO Waiting up to 40m0s for bootstrapping to complete...
```

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

### Set required environment variables

```
export TF_VAR_dns_domain=okd4.example.com
export TF_VAR_dns_zone_id=14758f1afd44c09b7992073ccf00b43d
export HCLOUD_TOKEN=14758f1afd44c09b7992073ccf00b43d14758f1afd44c09b7992073ccf00b43d
export CLOUDFLARE_EMAIL=user@example.com
export CLOUDFLARE_API_KEY=14758f1afd44c09b7992073ccf00b43d
```

### Create Fedora CoreOS image

Build a Fedora CoreOS hcloud image and embed the hcloud user data source (`http://169.254.169.254/hetzner/v1/userdata`).

Because the Fedora CoreOS image will be stored in RAM during the build, at least a cx31 instance is required.

```
make hcloud_image
```

### Create Boostrap image

Build a second hcloud image, especially the inital cluster boostrap. Special handling is required here, as the user_data field is limited to 32 Kib (#18).

```
hcloud_boostrap_image
```

### Build infrastructure with Terraform

```
make infrastructure BOOTSTRAP=true
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

```
make infrastructure
```

## Author

- [slauger](https://github.com/slauger)
