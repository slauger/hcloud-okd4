# Fixed private addresses, so the node IP hint can name the exact address.
# hcloud assigns them as /32, a hint for the subnet would not match.
locals {
  private_ipv4_addresses = [for i in range(var.instance_count) : cidrhost(var.subnet_cidr, var.ip_offset + i)]
}
