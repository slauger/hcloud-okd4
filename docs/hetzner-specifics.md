# Hetzner Cloud Specifics

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
| Load balancer services listen on the public and the private IP, cloud firewalls cannot be attached to load balancers | The machine config server (22623), which hands out node configs including bootstrap credentials, would be reachable from the internet | Separate internal load balancer without public interface for `api-int` (API and MCS), the public one only serves API and ingress | `terraform/loadbalancer.tf` |
| Cloud firewalls do not filter private network traffic | Per-port rules with node IPs are not needed | One firewall per cluster, only ICMP on the public interfaces | `terraform/firewall.tf` |
| Neither SLAAC nor DHCPv6 | Nodes only have link-local IPv6 | Pre-allocated IPv6 primary IP per node, configured statically (`<prefix>::1/64`, gateway `fe80::1`) | `terraform/modules/hcloud_coreos/network.tf` |
| No cloud-init on CoreOS, user data is served by the metadata service | CoreOS does not read it on its own | The image embeds an ignition config that merges `http://169.254.169.254/hetzner/v1/userdata` | `packer/config-3.0.0.ign` |
| Network interfaces are named `enp1s0` (public) and `enp7s0` (private network) | Network profiles match on interface names | Configurable via `public_interface` / `private_interface` | `terraform/modules/hcloud_coreos/variables.tf` |
| Images built on a server keep its disk size | The snapshot (cpx32, 160 GB) only fits on server types with at least that disk | Use cpx32 or larger for all nodes | `packer/*.json` |
| OKD publishes amd64 release payloads only, its arm64 binaries just run the installer on arm64 hosts | arm64 (CAX) clusters are not possible with OKD | `ARCH=arm64` is OCP only and uses the `aarch64` release payload | `Makefile` |
| First generation CPX types are no longer orderable in the EU | Old configurations fail | cpx22 / cpx32 / cpx42 | `terraform/main.tf`, `packer/*.json` |

See the [README](../README.md) for the overall architecture and the deployment steps.
