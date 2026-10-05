locals {
  cloudflare_dns = var.dns_provider == "cloudflare"

  # Records the cluster needs. With dns_provider = "none" they have to be
  # created manually, api-int and the node records before the nodes boot.
  dns_records = concat(
    [
      { name = "api.${var.dns_domain}", type = "A", value = hcloud_load_balancer.lb.ipv4 },
      { name = "api-int.${var.dns_domain}", type = "A", value = hcloud_load_balancer_network.lb_network.ip },
      { name = "apps.${var.dns_domain}", type = "A", value = hcloud_load_balancer.lb.ipv4 },
      { name = "*.apps.${var.dns_domain}", type = "A", value = hcloud_load_balancer.lb.ipv4 },
    ],
    [for m in [module.bootstrap, module.master, module.worker] : [
      for i, name in m.server_names : { name = name, type = "A", value = m.internal_ipv4_addresses[i] }
    ]]...
  )
}

resource "cloudflare_dns_record" "dns_a_api" {
  count   = local.cloudflare_dns ? 1 : 0
  zone_id = var.dns_zone_id
  name    = "api.${var.dns_domain}"
  content = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 120
}

resource "cloudflare_dns_record" "dns_a_api_int" {
  count   = local.cloudflare_dns ? 1 : 0
  zone_id = var.dns_zone_id
  name    = "api-int.${var.dns_domain}"
  content = hcloud_load_balancer_network.lb_network.ip
  type    = "A"
  ttl     = 120

  lifecycle {
    precondition {
      condition     = var.dns_zone_id != null
      error_message = "dns_zone_id is required for dns_provider = cloudflare."
    }
  }
}

resource "cloudflare_dns_record" "dns_a_apps" {
  count   = local.cloudflare_dns ? 1 : 0
  zone_id = var.dns_zone_id
  name    = "apps.${var.dns_domain}"
  content = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 120
}

resource "cloudflare_dns_record" "dns_a_apps_wc" {
  count   = local.cloudflare_dns ? 1 : 0
  zone_id = var.dns_zone_id
  name    = "*.apps.${var.dns_domain}"
  content = hcloud_load_balancer.lb.ipv4
  type    = "A"
  ttl     = 120
}
