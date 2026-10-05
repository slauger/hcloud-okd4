![Docker Build](https://github.com/slauger/hcloud-okd4/workflows/Docker%20Build/badge.svg)

# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud using HashiCorp Packer and Terraform.

![OKD4 on Hetzner Cloud](https://raw.githubusercontent.com/slauger/hcloud-okd4/master/okd4-hcloud.png)

---

## Deploy with a Coding Agent

Need an OKD test cluster? Copy the following prompt into your AI coding agent of choice and let it do the work:

```text
Deploy an OKD test cluster on Hetzner Cloud using https://github.com/slauger/hcloud-okd4.

1. Clone the repository and read the README.
2. Ask me for everything you need and do not have yet: Hetzner Cloud API token,
   Cloudflare e-mail, API key and zone ID, the cluster domain (e.g. okd4.example.com),
   the Hetzner Object Storage bucket and S3 credentials, my SSH public key and the
   number of worker nodes. Keep secrets in a local env.sh only and never commit them.
3. Determine the latest stable OKD release with `make latest_version`, fetch the
   binaries and build the toolbox image. Run all further make targets inside the
   toolbox container non-interactively (docker run ... make <target>).
4. Create install-config.yaml from the README example, generate manifests and
   ignition configs and build the CoreOS image with Packer.
5. Before creating any billable infrastructure, show me what will be created and
   wait for my confirmation.
6. Follow the Quick Start: deploy with BOOTSTRAP=true, wait for the bootstrap to
   complete, remove the bootstrap node, approve CSRs until all nodes are Ready and
   wait for the installation to complete.
7. If a step fails, find the root cause (nodes, cluster operators, load balancer
   health checks) instead of blindly retrying.
8. When finished, give me the console URL and the paths to the kubeconfig and the
   kubeadmin password.
```

---

## Architecture

By default, a single-node cluster is deployed with the following components:

| Component     | Type / Size |
|---------------|-------------|
| Master Node   | cpx42       |
| Load Balancer | lb11        |
| Bootstrap Node| cpx42 (removed after bootstrap) |

The bootstrap ignition config is too large for Hetzner Cloud user data. It is therefore uploaded to a private Hetzner Object Storage bucket and the bootstrap node fetches it through a short-lived pre-signed HTTPS URL.

### Networking

All nodes are attached to a Hetzner private network. Cluster traffic (etcd, API, OVN-Kubernetes overlay, kubelet) uses the private interface, while the public interface is only used as default route for outbound traffic. The load balancer reaches its targets via their private IPs, and `api-int` as well as the node DNS records resolve to private addresses. The overlay MTU is lowered to 1350 to fit the private network (MTU 1450), see `manifests/cluster-network-03-config.yml`.

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

- Nodes are **not directly exposed to the internet**: the hcloud firewall only allows ICMP on their public interfaces. Hetzner firewalls do not apply to private networks, so cluster traffic is not affected.
- Only the load balancer is publicly accessible (API on 6443, ingress on 80/443).
- SSH access to nodes is only possible with additional firewall configuration.

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

- No stability guarantees for large clusters or production use.

---

## Author

[slauger](https://github.com/slauger)
