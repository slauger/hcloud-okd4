![Docker Build](https://github.com/slauger/hcloud-okd4/workflows/Docker%20Build/badge.svg)

# hcloud-okd4

Deploy OKD4 (OpenShift) on Hetzner Cloud using HashiCorp Packer and Terraform.

![OKD4 on Hetzner Cloud](https://raw.githubusercontent.com/slauger/hcloud-okd4/master/okd4-hcloud.png)

---

## Deploy with a Coding Agent

Need an OKD test cluster without reading all of this? Copy the prompt from [docs/coding-agent.md](docs/coding-agent.md) into your AI coding agent of choice.

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

Hetzner Cloud offers neither SLAAC nor DHCPv6, so each node gets a pre-allocated IPv6 primary IP, which is configured statically (`<prefix>::1/64`, gateway `fe80::1`) together with Cloudflare resolvers. The cluster network itself stays IPv4 only.

### Hetzner Cloud Specifics

Hetzner Cloud is not a supported OpenShift platform (`platform: none`), and several of its properties need special handling. If you change the setup, keep these in mind:

| Hetzner Cloud behavior | Consequence | Solution | Where |
|---|---|---|---|
| User data is limited to 32 KiB | The bootstrap ignition config (~300 KB) does not fit | Upload it to private Object Storage and pass a pre-signed HTTPS URL (24h) | `make upload_ignition`, `terraform/main.tf` |
| The hcloud resolvers cache records far beyond their TTL, including negative answers | A freshly created `api-int` record does not resolve during the first boot, nodes never fetch their config | First boot uses Cloudflare resolvers (`ignition.firstboot` in the image), the nodes keep them via NetworkManager, `api-int` is created before the nodes | `packer/*.json`, `terraform/modules/hcloud_coreos/network.tf` |
| Private network addresses are `/32`, all traffic is routed via the network gateway (no layer 2 between nodes) | `nodeip-configuration` cannot match a node IP hint and falls back to the public IP | NetworkManager profile adds the address with the subnet prefix, while routing the subnet via the gateway; hint is the subnet address | `terraform/modules/hcloud_coreos/network.tf` |
| OVN-Kubernetes puts `br-ex` on the interface of the node IP (private) and needs a default route there | Without it OVN does not start | Low priority default route via the network gateway on the private interface | `terraform/modules/hcloud_coreos/network.tf` |
| The private network has no internet gateway | Pod egress must leave through the public interface | `routingViaHost: true` and `ipForwarding: Global`, otherwise all pod egress is dropped | `manifests/cluster-network-03-config.yml` |
| The private network has an MTU of 1450 | Geneve adds 100 bytes | Overlay MTU 1350 | `manifests/cluster-network-03-config.yml` |
| The bootstrap etcd picks its address from `machineNetwork` | With the default `10.0.0.0/16` it advertises the public IP, which the firewall blocks | `machineNetwork` must be the private subnet | `install-config.yaml` |
| Cloud firewalls do not filter private network traffic | Per-port rules with node IPs are not needed | One firewall per cluster, only ICMP on the public interfaces | `terraform/firewall.tf` |
| Neither SLAAC nor DHCPv6 | Nodes only have link-local IPv6 | Pre-allocated IPv6 primary IP per node, configured statically (`<prefix>::1/64`, gateway `fe80::1`) | `terraform/modules/hcloud_coreos/network.tf` |
| No cloud-init on CoreOS, user data is served by the metadata service | CoreOS does not read it on its own | The image embeds an ignition config that merges `http://169.254.169.254/hetzner/v1/userdata` | `packer/config-3.0.0.ign` |
| Network interfaces are named `enp1s0` (public) and `enp7s0` (private network) | Network profiles match on interface names | Configurable via `public_interface` / `private_interface` | `terraform/modules/hcloud_coreos/variables.tf` |
| Images built on a server keep its disk size | The snapshot (cpx32, 160 GB) only fits on server types with at least that disk | Use cpx32 or larger for all nodes | `packer/*.json` |
| First generation CPX types are no longer orderable in the EU | Old configurations fail | cpx22 / cpx32 / cpx42 | `terraform/main.tf`, `packer/*.json` |

### Costs

Approximate prices, **as of 2026-10-05** (net, location `nbg1`, taken from the Hetzner Cloud pricing API). Prices change over time, check the current [Hetzner Cloud pricing](https://www.hetzner.com/cloud/) before deploying. Hetzner bills hourly, capped at the monthly price.

| Setup | Per hour | Per month |
|---|---|---|
| Single node (1× master cpx42, lb11, IPv4) | ~0.12 € | ~77 € |
| Default with 2 workers (3× cpx42, lb11, 3× IPv4) | ~0.35 € | ~217 € |
| Bootstrap node during installation (cpx42, billed as one hour) | ~0.11 € once | – |
| Additional volumes (`TF_VAR_*_volume_size`) | – | ~0.06 € per GB |
| CoreOS snapshot (~1 GB) | – | ~0.01 € |

Hetzner Object Storage is billed separately with a monthly base fee once a bucket exists, see the Hetzner pricing page.

### Duration

Measured with OKD 4.22 and OCP 4.22, 1 master and 2 workers:

| Step | Duration |
|---|---|
| Toolbox image (`make fetch build`) | ~5 min |
| CoreOS image (`make hcloud_image`) | ~10 min |
| Infrastructure (`make infrastructure BOOTSTRAP=true`) | ~3 min |
| Bootstrap (`make wait_bootstrap`) | ~12 min |
| Installation (`make wait_completion`) | ~15–25 min |
| **Total** | **~45–55 min**, ~30–40 min with an existing image |

Additional worker nodes can be added by setting an environment variable **before** running Terraform:

```bash
export TF_VAR_replicas_worker=3  # Example: 3 worker nodes
```

### Additional Disks (LVM Storage / Ceph)

Every master and worker node can get an additional, unformatted Hetzner Volume, e.g. for the LVM Storage operator or Rook-Ceph. Volumes can also be added to a running cluster:

```bash
export TF_VAR_worker_volume_size=100 # GB per worker, 0 (default) = no volume
export TF_VAR_master_volume_size=100 # GB per master, only useful if masters run workloads
make infrastructure
```

Inside the node the volume shows up as `/dev/sdb`, with a stable path below `/dev/disk/by-id/scsi-0HC_Volume_<volume id>`. Example for an `LVMCluster`:

```yaml
spec:
  storage:
    deviceClasses:
      - name: vg1
        deviceSelector:
          paths:
            - /dev/sdb
        thinPoolConfig:
          name: thin-pool-1
          sizePercent: 90
          overprovisionRatio: 10
```

For Rook-Ceph, set `useAllDevices: false` and select the volume with `deviceFilter: ^sdb$`. Hetzner Volumes are network attached block storage, which is fine for test clusters but not for performance testing.

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
  clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
  networkType: OVNKubernetes
  serviceNetwork:
    - 172.30.0.0/16
  machineNetwork:
    - cidr: 192.168.254.0/24 # has to match TF_VAR_subnet_cidr (default)
platform:
  none: {}
pullSecret: '{"auths":{"none":{"auth":"none"}}}'
sshKey: ssh-rsa AAAA…<your ssh key here>
```

`metadata.name` and `baseDomain` together form the cluster domain (`okd4.example.com` in this example), which has to match `TF_VAR_dns_domain`. `machineNetwork` has to be the private subnet of the nodes, otherwise the bootstrap etcd advertises its public address, which is not reachable through the firewall.

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
export OPENSHIFT_RELEASE=4.22.15 # example version
make fetch build run
```

You can also choose the latest version from a specific channel:

```bash
export OCP_RELEASE_CHANNEL=stable-4.22
export OPENSHIFT_RELEASE=$(make latest_version)
make fetch build run
```

---

## Limitations / Not for Production

- No stability guarantees for large clusters or production use.

---

## Author

[slauger](https://github.com/slauger)
