resource "hcloud_server" "server" {
  count       = var.instance_count
  name        = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}"
  image       = var.image
  server_type = var.server_type
  keep_disk   = var.keep_disk
  ssh_keys    = var.ssh_keys
  user_data   = data.template_file.ignition_config[count.index].rendered
  location    = var.location
  backups     = var.backups
  #  lifecycle {
  #    ignore_changes = [user_data, image]
  #  }
}

resource "hcloud_rdns" "dns-ptr-ipv4" {
  count      = var.instance_count
  server_id  = element(hcloud_server.server.*.id, count.index)
  ip_address = element(hcloud_server.server.*.ipv4_address, count.index)
  dns_ptr    = element(hcloud_server.server.*.name, count.index)
}

resource "hcloud_rdns" "dns-ptr-ipv6" {
  count      = var.instance_count
  server_id  = element(hcloud_server.server.*.id, count.index)
  ip_address = "${element(hcloud_server.server.*.ipv6_address, count.index)}1"
  dns_ptr    = element(hcloud_server.server.*.name, count.index)
}
