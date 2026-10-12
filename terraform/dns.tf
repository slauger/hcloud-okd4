locals {
  # Records the cluster needs. With dns_provider = "none" they have to be
  # created manually, api-int and the node records before the nodes boot.
  dns_records = merge(
    {
      api             = { name = "api.${var.dns_domain}", type = "A", value = hcloud_load_balancer.lb.ipv4 }
      "api-int"       = { name = "api-int.${var.dns_domain}", type = "A", value = hcloud_load_balancer_network.internal.ip }
      apps            = { name = "apps.${var.dns_domain}", type = "A", value = hcloud_load_balancer.lb.ipv4 }
      "apps-wildcard" = { name = "*.apps.${var.dns_domain}", type = "A", value = hcloud_load_balancer.lb.ipv4 }
    },
    [for role, n in local.nodes : {
      for i in range(n.count) : format("%s%02d", role, i + 1) => {
        name  = format("%s%02d.%s", role, i + 1, var.dns_domain)
        type  = "A"
        value = cidrhost(var.subnet_cidr, n.ip_offset + i)
      }
    }]...
  )

  # baseDomain of install-config.yaml, the cluster domain without metadata.name
  base_domain = join(".", slice(split(".", var.dns_domain), 1, length(split(".", var.dns_domain))))
}

module "dns" {
  source             = "./modules/dns"
  provider_name      = var.dns_provider
  records            = local.dns_records
  cloudflare_zone_id = var.dns_zone_id
  hetzner_zone       = coalesce(var.dns_zone, local.base_domain)
}

moved {
  from = cloudflare_dns_record.dns_a_api[0]
  to   = module.dns.cloudflare_dns_record.record["api"]
}

moved {
  from = cloudflare_dns_record.dns_a_api_int[0]
  to   = module.dns.cloudflare_dns_record.record["api-int"]
}

moved {
  from = cloudflare_dns_record.dns_a_apps[0]
  to   = module.dns.cloudflare_dns_record.record["apps"]
}

moved {
  from = cloudflare_dns_record.dns_a_apps_wc[0]
  to   = module.dns.cloudflare_dns_record.record["apps-wildcard"]
}
