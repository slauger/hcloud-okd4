resource "cloudflare_record" "dns_a_ignition" {
  zone_id = var.dns_zone_id
  name    = "ignition.${var.dns_domain}"
  value   = module.ignition.ipv4_addresses[0]
  type    = "A"
  ttl     = 1
  count   = var.bootstrap == true ? 1 : 0
}

resource "cloudflare_record" "dns_a_api" {
  zone_id = var.dns_zone_id
  name    = "api.${var.dns_domain}"
  value   = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "dns_a_api_int" {
  zone_id = var.dns_zone_id
  name    = "api-int.${var.dns_domain}"
  value   = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "dns_a_apps" {
  zone_id = var.dns_zone_id
  name    = "apps.${var.dns_domain}"
  value   = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "dns_a_apps_wc" {
  zone_id = var.dns_zone_id
  name    = "*.apps.${var.dns_domain}"
  value   = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "dns_a_etcd" {
  zone_id = var.dns_zone_id
  name    = "etcd-${count.index}.${var.dns_domain}"
  value   = module.master.ipv4_addresses[count.index]
  type    = "A"
  ttl     = 1

  count = length(module.master.ipv4_addresses)
}

resource "cloudflare_record" "dns_srv_etcd" {
  zone_id = var.dns_zone_id
  name    = "_etcd-server-ssl._tcp.${var.dns_domain}"
  value   = "0\t2380\tetcd-${count.index}.${var.dns_domain}"
  type    = "SRV"

  lifecycle {
    ignore_changes = [data]
  }

  count = length(module.master.ipv4_addresses)
}
