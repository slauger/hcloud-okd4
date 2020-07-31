![Docker Build](https://github.com/slauger/hcloud-okd4/workflows/Docker%20Build/badge.svg) [![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=slauger/hcloud-okd4)](https://dependabot.com)


# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud using Hashicorp Packer, Terraform and Ansible.

## Current status

The Hetzner Cloud does not fulfill the I/O performance/latency requirements for etcd - even when using local SSDs (instead of ceph storage). This could result in different problems during the cluster bootstrap. You could check the I/O performance via `etcdctl check perf`.

Because of that OpenShift on hcloud is only suitable for small test environments. Please do not use it for production clusters.

## Architecture

The deployment defaults to a single node cluster.

- 1x Master Node (CX41)
- 1x Loadbalancer (LB11)
- 1x Bootstrap Node (CX41) - deleted after cluster bootstrap
- 1x Ignition Node (CX11) - deleted after cluster bootstrap

## Usage

### Build toolbox

To ensure that the we have a proper build environment, we create a toolbox container first.

```
make fetch
make build
```

If you do not want to build the container by your own, it is also available on [Docker Hub](https://hub.docker.com/repository/docker/cmon2k/openshift-toolbox).

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

This step is not necessary if you set `replicas_worker` to zero.

## Hetzner CSI

To install the CSI driver create a secret with your hcloud token first.

```
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-csi
  namespace: kube-system
stringData:
  token: ${HCLOUD_TOKEN}
EOF
```

After that just apply the the following manifest.

```
oc apply -f https://raw.githubusercontent.com/slauger/csi-driver/openshift/deploy/kubernetes/hcloud-csi-openshift.yml
```

## Deployment of OCP

It's also possible OCP (with RedHat CoreOS) instead of OKD. Just add the suffix `DEPLOYMENT_TYPE=ocp` to each `make` command. For example:

```
make fetch DEPLOYMENT_TYPE=ocp
make fetch DEPLOYMENT_TYPE=ocp
```

Besides that a RedHat OpenShift pull secret is necessary, which could be obtained from [cloud.redhat.com](https://cloud.redhat.com/).

## Author

- [slauger](https://github.com/slauger)
