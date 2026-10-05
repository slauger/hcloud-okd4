resource "cloudflare_dns_record" "dns_a_api" {
  zone_id = var.dns_zone_id
  name    = "api.${var.dns_domain}"
  content = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 120
}

resource "cloudflare_dns_record" "dns_a_api_int" {
  zone_id = var.dns_zone_id
  name    = "api-int.${var.dns_domain}"
  content = hcloud_load_balancer_network.lb_network.ip
  type    = "A"
  ttl     = 120
}

resource "cloudflare_dns_record" "dns_a_apps" {
  zone_id = var.dns_zone_id
  name    = "apps.${var.dns_domain}"
  content = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 120
}

resource "cloudflare_dns_record" "dns_a_apps_wc" {
  zone_id = var.dns_zone_id
  name    = "*.apps.${var.dns_domain}"
  content = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 120
}

resource "cloudflare_dns_record" "dns_a_etcd" {
  zone_id = var.dns_zone_id
  name    = "etcd-${count.index}.${var.dns_domain}"
  content = module.master.internal_ipv4_addresses[count.index]
  type    = "A"
  ttl     = 120

  count = var.replicas_master
}

resource "cloudflare_dns_record" "dns_srv_etcd" {
  zone_id = var.dns_zone_id
  name    = "_etcd-server-ssl._tcp.${var.dns_domain}"
  type    = "SRV"
  ttl     = 120

  data = {
    service  = "_etcd-server-ssl"
    proto    = "_tcp"
    name     = "_etcd-server-ssl._tcp.${var.dns_domain}"
    priority = 0
    weight   = 0
    port     = 2380
    target   = "etcd-${count.index}.${var.dns_domain}"
  }

  count = var.replicas_master
}
