resource "hcloud_server" "server" {
  count       = var.instance_count
  name        = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}"
  image       = var.image
  server_type = var.server_type
  keep_disk   = var.keep_disk
  ssh_keys    = var.ssh_keys
  user_data = templatefile("${path.module}/templates/ignition.ign", {
    hostname         = format("%s%02d.%s", var.name, count.index + 1, var.dns_domain)
    hostname_b64     = base64encode(format("%s%02d.%s", var.name, count.index + 1, var.dns_domain))
    ignition_url     = var.ignition_url
    ignition_version = var.ignition_version
    ignition_cacert  = var.ignition_cacert
    nodeip_hint      = cidrhost(var.subnet_cidr, 0)
    private_nm_b64   = base64encode(local.private_nmconnection[count.index])
    public_nm_b64    = base64encode(local.public_nmconnection[count.index])
  })
  location = var.location
  public_net {
    ipv4_enabled = true
    ipv6         = hcloud_primary_ip.ipv6[count.index].id
  }
  network {
    network_id = var.network_id
    ip         = local.private_ipv4_addresses[count.index]
  }
  labels       = var.labels
  backups      = var.backups
  firewall_ids = var.firewall_ids
  lifecycle {
    ignore_changes = [user_data, image, firewall_ids]
  }
}

resource "hcloud_rdns" "dns-ptr-ipv4" {
  count      = var.instance_count
  server_id  = element(hcloud_server.server[*].id, count.index)
  ip_address = element(hcloud_server.server[*].ipv4_address, count.index)
  dns_ptr    = element(hcloud_server.server[*].name, count.index)
}

resource "hcloud_rdns" "dns-ptr-ipv6" {
  count      = var.instance_count
  server_id  = element(hcloud_server.server[*].id, count.index)
  ip_address = local.public_ipv6_addresses[count.index]
  dns_ptr    = element(hcloud_server.server[*].name, count.index)
}
