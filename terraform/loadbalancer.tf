resource "cloudflare_load_balancer" "loadbalancer_bootstrap_api" {
  name             = "api.${var.dns_domain}"
  zone_id          = var.dns_zone_id
  default_pool_ids = [cloudflare_load_balancer_pool.master_pool[0].id, cloudflare_load_balancer_pool.bootstrap_pool[0].id]
  fallback_pool_id = cloudflare_load_balancer_pool.bootstrap_pool[0].id
  description      = "Loadbalancer for api.${var.dns_domain}"
  count            = (var.cloudflare_loadbalancing == true && var.bootstrap == true) ? 1 : 0
}

resource "cloudflare_load_balancer" "loadbalancer_bootstrap_api_int" {
  name             = "api-int.${var.dns_domain}"
  zone_id          = var.dns_zone_id
  default_pool_ids = [cloudflare_load_balancer_pool.master_pool[0].id, cloudflare_load_balancer_pool.bootstrap_pool[0].id]
  fallback_pool_id = cloudflare_load_balancer_pool.bootstrap_pool[0].id
  description      = "Loadbalancer for api-int.${var.dns_domain}"
  count            = (var.cloudflare_loadbalancing == true && var.bootstrap == true) ? 1 : 0
}

resource "cloudflare_load_balancer" "loadbalancer_api" {
  name             = "api.${var.dns_domain}"
  zone_id          = var.dns_zone_id
  default_pool_ids = [cloudflare_load_balancer_pool.master_pool[0].id]
  fallback_pool_id = cloudflare_load_balancer_pool.master_pool[0].id
  description      = "Loadbalancer for api.${var.dns_domain}"
  count            = (var.cloudflare_loadbalancing == true && var.bootstrap == false) ? 1 : 0
}

resource "cloudflare_load_balancer" "loadbalancer_api_int" {
  name             = "api-int.${var.dns_domain}"
  zone_id          = var.dns_zone_id
  default_pool_ids = [cloudflare_load_balancer_pool.master_pool[0].id]
  fallback_pool_id = cloudflare_load_balancer_pool.master_pool[0].id
  description      = "Loadbalancer for api.${var.dns_domain}"
  count            = (var.cloudflare_loadbalancing == true && var.bootstrap == false) ? 1 : 0
}

resource "cloudflare_load_balancer" "loadbalancer_apps" {
  name             = "apps.${var.dns_domain}"
  zone_id          = var.dns_zone_id
  default_pool_ids = [cloudflare_load_balancer_pool.worker_pool[0].id, cloudflare_load_balancer_pool.master_pool[0].id]
  fallback_pool_id = cloudflare_load_balancer_pool.master_pool[0].id
  description      = "Loadbalancer for apps.${var.dns_domain}"
  count            = var.cloudflare_loadbalancing == true ? 1 : 0
}

resource "cloudflare_load_balancer" "loadbalancer_apps_wc" {
  name             = "*.apps.${var.dns_domain}"
  zone_id          = var.dns_zone_id
  default_pool_ids = [cloudflare_load_balancer_pool.worker_pool[0].id, cloudflare_load_balancer_pool.master_pool[0].id]
  fallback_pool_id = cloudflare_load_balancer_pool.master_pool[0].id
  description      = "Loadbalancer for apps.${var.dns_domain}"
  count            = var.cloudflare_loadbalancing == true ? 1 : 0
}
