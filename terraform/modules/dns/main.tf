resource "cloudflare_dns_record" "record" {
  for_each = var.provider_name == "cloudflare" ? var.records : {}
  zone_id  = var.cloudflare_zone_id
  name     = each.value.name
  content  = each.value.value
  type     = each.value.type
  ttl      = var.ttl

  lifecycle {
    precondition {
      condition     = var.cloudflare_zone_id != null
      error_message = "dns_zone_id is required for dns_provider = cloudflare."
    }
  }
}

# Hetzner DNS manages record sets with names relative to the zone.
resource "hcloud_zone_rrset" "record" {
  for_each = var.provider_name == "hetzner" ? var.records : {}
  zone     = var.hetzner_zone
  name     = each.value.name == var.hetzner_zone ? "@" : trimsuffix(each.value.name, ".${var.hetzner_zone}")
  type     = each.value.type
  ttl      = var.ttl
  records  = [{ value = each.value.value }]

  lifecycle {
    precondition {
      condition     = var.hetzner_zone != null && (each.value.name == var.hetzner_zone || endswith(each.value.name, ".${var.hetzner_zone}"))
      error_message = "The record ${each.value.name} is not part of the Hetzner DNS zone ${coalesce(var.hetzner_zone, "(unset)")}, set dns_zone."
    }
  }
}
