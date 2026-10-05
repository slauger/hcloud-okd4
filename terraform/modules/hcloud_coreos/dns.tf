resource "cloudflare_dns_record" "dns-a" {
  count   = var.instance_count
  zone_id = var.dns_zone_id
  name    = element(hcloud_server.server.*.name, count.index)
  content = var.dns_internal_ip == true ? local.private_ipv4_addresses[count.index] : hcloud_server.server[count.index].ipv4_address
  type    = "A"
  ttl     = 120
}
