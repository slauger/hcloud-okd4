module "bootstrap" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.bootstrap == true ? 1 : 0
  location        = var.location
  name            = "bootstrap"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = true
  image           = data.hcloud_image.image.id
  image_name      = var.image
  server_type     = "cpx42"
  labels = {
    "cluster" = var.dns_domain
  }
  network_id   = hcloud_network_subnet.subnet.network_id
  nodeip_hint  = cidrhost(var.subnet_cidr, 0)
  ignition_url = var.bootstrap == true ? var.bootstrap_ignition_url : ""
}

module "master" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.replicas_master
  location        = var.location
  name            = "master"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = true
  image           = data.hcloud_image.image.id
  image_name      = var.image
  server_type     = "cpx42"
  labels = {
    "${var.dns_domain}/master"  = "true",
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  nodeip_hint     = cidrhost(var.subnet_cidr, 0)
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/master"
  ignition_cacert = local.ignition_master_cacert

  # Resolvers cache negative answers, so api-int has to exist before the
  # nodes try to resolve it during their first boot.
  depends_on = [cloudflare_dns_record.dns_a_api_int]
}

module "worker" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.replicas_worker
  location        = var.location
  name            = "worker"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = true
  image           = data.hcloud_image.image.id
  image_name      = var.image
  server_type     = "cpx42"
  labels = {
    "${var.dns_domain}/worker"  = "true"
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  nodeip_hint     = cidrhost(var.subnet_cidr, 0)
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert = local.ignition_worker_cacert

  # Resolvers cache negative answers, so api-int has to exist before the
  # nodes try to resolve it during their first boot.
  depends_on = [cloudflare_dns_record.dns_a_api_int]
}
