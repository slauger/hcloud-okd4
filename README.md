![Docker Build](https://github.com/slauger/hcloud-okd4/workflows/Docker%20Build/badge.svg)


# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud using Hashicorp Packer, Terraform and Ansible.

![OKD4 on Hetzner Cloud](screenshot.png)

## Current status

The Hetzner Cloud does not fulfill the I/O performance/latency requirements for etcd - even when using local SSDs (instead of ceph storage). This could result in different problems during the cluster bootstrap. You could check the I/O performance via `etcdctl check perf`.

Because of that OpenShift on hcloud is only suitable for small test environments. Please do not use it for production clusters.

## Architecture

The deployment defaults to a single node cluster.

- 1x Master Node (cpx41)
- 1x Loadbalancer (lb11)
- 1x Bootstrap Node (cpx41) - deleted after cluster bootstrap
- 1x Ignition Node (cpx21) - deleted after cluster bootstrap

Additional worker nodes can be added via the following environment variable (during terraform deployment).

```
export TF_VAR_replicas_worker=3 # deploy 3 worker nodes
```

## Usage

### Set Version

Set a target version via the `OPENSHIFT_RELEASE` environment variable. You could also use the `latest_version` target to fetch the latest available version.

```
export DEPLOYMENT_TYPE=okd # "okd" or "ocp", default is "okd"
export OPENSHIFT_RELEASE=$(make latest_version)
```

### Build toolbox

To ensure that the we have a proper build environment, we create a toolbox container first.

```
make fetch
make build
```

If you do not want to build the container by your own, it is also available on [quay.io](https://quay.io/repository/slauger/hcloud-okd4).

### Run toolbox

Use the following command to start the container.

```
make run
```

All the following commands will be executed inside the container. 

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
  replicas: 1
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OVNKubernetes
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
make generate_manifests
```

### Create ignition config

```
make generate_ignition
```

### Set required environment variables

```
# terraform variables
export TF_VAR_dns_domain=okd4.example.com
export TF_VAR_dns_zone_id=14758f1afd44c09b7992073ccf00b43d

# credentials for hcloud
export HCLOUD_TOKEN=14758f1afd44c09b7992073ccf00b43d14758f1afd44c09b7992073ccf00b43d

# credentials for cloudflare
export CLOUDFLARE_EMAIL=user@example.com
export CLOUDFLARE_API_KEY=14758f1afd44c09b7992073ccf00b43d
```

### Create Fedora CoreOS image

Build a Fedora CoreOS hcloud image with Packer and embed the hcloud user data source (`http://169.254.169.254/hetzner/v1/userdata`).

```
make hcloud_image
```

### Build infrastructure with Terraform

```
make infrastructure BOOTSTRAP=true
```

### Wait for the bootstrap to complete

```
make wait_bootstrap
```

### Cleanup bootstrap and ignition node

```
make infrastructure
```

### Finish the installation process

```
make wait_completion
```

### Sign Worker CSRs

CSRs of the master nodes get signed by the bootstrap node automaticaly during the cluster bootstrap. CSRs from worker nodes must be signed manually.

```
make sign_csr
sleep 60
make sign_csr
```

This step is only necessary if you set `TF_VAR_replicas_worker` to >= 1.

## Deployment of OCP

It's also possible OCP (with RedHat CoreOS) instead of OKD. Just export `DEPLOYMENT_TYPE=ocp`. For example:

```
export DEPLOYMENT_TYPE=ocp
export OPENSHIFT_RELEASE=4.19.10
make fetch build run
```

You can also select the latest version from a specific channel via:

```
export OCP_RELEASE_CHANNEL=stable-4.19
export OPENSHIFT_RELEASE=$(make latest_version)
make fetch build run
```

To setup OCP a pull secret in your install-config.yaml is necessary, which could be obtained from [cloud.redhat.com](https://cloud.redhat.com/).

## Firewall rules

Nodes will be pingable but isolated from the internet. The cluster is only reachable through the load balancer. If you require direct SSH access, you can add another rule to the nodes that allows access to port 22.

## Cloudflare API Token

Checkout [this issue](https://github.com/slauger/hcloud-okd4/issues/176) to get details about how to obtain an API token for the Cloudflare API.

## Author

- [slauger](https://github.com/slauger)
