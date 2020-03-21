# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud and Cloudflare with Hashicorp Packer and Terraform.

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
export TF_VAR_dns_domain=example.com
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

### Build infrastructure with Terraform

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

```
make infrastructure
```

## Author

- [slauger](https://github.com/slauger)
