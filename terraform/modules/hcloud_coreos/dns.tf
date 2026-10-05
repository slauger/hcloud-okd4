resource "cloudflare_dns_record" "dns-a" {
  count   = var.dns_records ? var.instance_count : 0
  zone_id = var.dns_zone_id
  name    = hcloud_server.server[count.index].name
  content = local.private_ipv4_addresses[count.index]
  type    = "A"
  ttl     = 120
}
