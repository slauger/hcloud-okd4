locals {
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
