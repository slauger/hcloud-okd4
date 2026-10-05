# hcloud does not offer SLAAC or DHCPv6, so the IPv6 address has to be
# configured statically. Allocating it upfront makes it known before the
# server (and its user data) is created.
resource "hcloud_primary_ip" "ipv6" {
  count       = var.instance_count
  name        = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}-ipv6"
  type        = "ipv6"
  location    = var.location
  auto_delete = true
  labels      = var.labels
}

locals {
  public_ipv6_addresses = [for ip in hcloud_primary_ip.ipv6 : cidrhost(ip.ip_network, 1)]

  # Public interface: IPv4 via DHCP, IPv6 static. Use public resolvers, the
  # hcloud resolvers cache records far beyond their TTL.
  public_nmconnection = [for ip in local.public_ipv6_addresses : <<-EOT
    [connection]
    id=public
    type=ethernet
    interface-name=${var.public_interface}
    autoconnect-priority=100

    [ipv4]
    method=auto
    ignore-auto-dns=true
    dns=${join(";", var.nameservers_ipv4)};

    [ipv6]
    method=manual
    address1=${ip}/64
    gateway=fe80::1
    dns=${join(";", var.nameservers_ipv6)};
    EOT
  ]

  # Fixed private addresses, so DNS records and the network profile can
  # refer to them before the servers exist.
  private_ipv4_addresses = [for i in range(var.instance_count) : cidrhost(var.subnet_cidr, var.ip_offset + i)]

  # hcloud hands out private addresses as /32 and only routes via the network
  # gateway. nodeip-configuration needs an address whose prefix contains the
  # hint, so add the address with the subnet prefix, but keep routing all
  # private traffic via the gateway. The low priority default route is
  # required by OVN-Kubernetes once br-ex is attached to this interface.
  private_nmconnection = [for ip in local.private_ipv4_addresses : <<-EOT
    [connection]
    id=private
    type=ethernet
    interface-name=${var.private_interface}
    autoconnect-priority=100

    [ipv4]
    method=auto
    address1=${ip}/${split("/", var.subnet_cidr)[1]}
    route1=${var.subnet_cidr},${var.network_gateway},10
    route1_options=onlink=true
    route2=0.0.0.0/0,${var.network_gateway},1000
    route2_options=onlink=true
    ignore-auto-dns=true

    [ipv6]
    method=ignore
    EOT
  ]
}
