resource "cloudflare_record" "dns-a" {
  count   = var.instance_count
  zone_id = var.dns_zone_id
  name    = element(hcloud_server.server.*.name, count.index)
  # value   = var.dns_internal_ip == true ? element(hcloud_server_network.server_network.*.ip, count.index) : element(hcloud_server.server.*.ipv4_address, count.index)
  value = element(hcloud_server.server.*.ipv4_address, count.index)
  type  = "A"
  ttl   = 1
}
