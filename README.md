![Docker Build](https://github.com/slauger/hcloud-okd4/workflows/Docker%20Build/badge.svg)

# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud using HashiCorp Packer and Terraform.

![OKD4 on Hetzner Cloud](https://raw.githubusercontent.com/slauger/hcloud-okd4/master/okd4-hcloud.png)

---

## Important Notice

Hetzner Cloud does **not** meet the I/O performance and latency requirements for etcd – even when using local SSDs (not Ceph). This may cause issues during the cluster bootstrap phase.

This setup is suitable for small test environments only. Not recommended for production clusters.

---

## Architecture

By default, a single-node cluster is deployed with the following components:

| Component     | Type / Size |
|---------------|-------------|
| Master Node   | cpx42       |
| Load Balancer | lb11        |
| Bootstrap Node| cpx42 (removed after bootstrap) |

The bootstrap ignition config is too large for Hetzner Cloud user data. It is therefore uploaded to a private Hetzner Object Storage bucket and the bootstrap node fetches it through a short-lived pre-signed HTTPS URL.

Additional worker nodes can be added by setting an environment variable **before** running Terraform:

```bash
export TF_VAR_replicas_worker=3  # Example: 3 worker nodes
```

---

## Version & Deployment Options

You can set the desired release version with the `OPENSHIFT_RELEASE` environment variable.

Example:

```bash
export DEPLOYMENT_TYPE=okd # Options: "okd" or "ocp", default is "okd"
export OPENSHIFT_RELEASE=$(make latest_version) # or a fixed version like "4.22.0-okd-scos.9"
```

`make latest_version` returns the most recent stable (non pre-release) OKD release. To stay on a specific minor stream, set `OKD_RELEASE_STREAM`:

```bash
export OPENSHIFT_RELEASE=$(make latest_version OKD_RELEASE_STREAM=4.22)
```

For OCP (Red Hat OpenShift), you will also need a valid pull secret, available from cloud.redhat.com.

---

## Quick Start

1. Build and start the toolbox
   ```bash
   make fetch
   make build
   make run
   ```
2. Create `install-config.yaml` (see example in *Configuration*)
3. Generate manifests
   ```bash
   make generate_manifests
   ```
4. Generate ignition configs
   ```bash
   make generate_ignition
   ```
5. Export required environment variables (see example in *Configuration*)
6. Build CentOS Stream CoreOS (OKD) or Red Hat CoreOS (OCP) image using Packer
   ```bash
   make hcloud_image
   ```
7. Deploy infrastructure with Terraform (uploads the bootstrap ignition config to Object Storage and creates the bootstrap node)
   ```bash
   make infrastructure BOOTSTRAP=true
   ```
8. Wait for bootstrap completion
   ```bash
   make wait_bootstrap
   ```
9. Remove bootstrap node (also deletes the bootstrap ignition config from Object Storage)
   ```bash
   make infrastructure
   ```
10. Wait for installation to finish
    ```bash
    make wait_completion
    ```
11. Approve worker CSRs (if workers are deployed)
    ```bash
    make sign_csr
    sleep 60
    make sign_csr
    ```
---

## Configuration

### Example: install-config.yaml

```yaml
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
platform:
  none: {}
pullSecret: '{"auths":{"none":{"auth":"none"}}}'
sshKey: ssh-rsa AAAA…<your ssh key here>
```

### Required Environment Variables

```bash
# Terraform / DNS
export TF_VAR_dns_domain=okd4.example.com
export TF_VAR_dns_zone_id=YOUR_ZONE_ID

# Hetzner Cloud credentials
export HCLOUD_TOKEN=YOUR_HCLOUD_TOKEN

# Cloudflare credentials
export CLOUDFLARE_EMAIL=user@example.com
export CLOUDFLARE_API_KEY=YOUR_API_KEY

# Hetzner Object Storage (bootstrap ignition config)
export S3_BUCKET=YOUR_BUCKET
export S3_LOCATION=nbg1 # optional, default: nbg1
export AWS_ACCESS_KEY_ID=YOUR_S3_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_S3_SECRET_KEY
```

### Object Storage

Hetzner does not offer an API to manage Object Storage credentials, so the bucket and the S3 credentials have to be created once in the Hetzner Console (*Object Storage* and *Security → S3 Credentials*). Keep the bucket private, access is granted through a pre-signed URL that expires after 24 hours (`S3_PRESIGN_EXPIRY`, matching the lifetime of the ignition certificates).

The config can also be uploaded or removed manually:

```bash
make upload_ignition
make delete_ignition
```

---

## Firewall & Access

- Nodes are **not directly exposed to the internet** by default.
- Only the load balancer is public accessible.
- SSH access to nodes will only be possible with additional firewall configuration.

---

## Deploying OCP (Red Hat OpenShift)

To deploy OCP instead of OKD:

```bash
export DEPLOYMENT_TYPE=ocp
export OPENSHIFT_RELEASE=4.19.9 # example version
make fetch build run
```

You can also choose the latest version from a specific channel:

```bash
export OCP_RELEASE_CHANNEL=stable-4.19
export OPENSHIFT_RELEASE=$(make latest_version)
make fetch build run
```

---

## Limitations / Not for Production

- I/O performance and latency issues with etcd (see above).
- Components that rely on strong consistency (like etcd) may suffer under heavy load.
- No stability guarantees for large clusters or production use.

---

## Author

[slauger](https://github.com/slauger)
