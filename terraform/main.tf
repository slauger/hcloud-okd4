module "bootstrap" {
  source           = "./modules/hcloud_coreos"
  instance_count   = var.bootstrap == true ? 1 : 0
  location         = var.location
  name             = "bootstrap"
  dns_domain       = var.dns_domain
  dns_zone_id      = var.dns_zone_id
  dns_records      = local.cloudflare_dns
  nameservers_ipv4 = var.nameservers_ipv4
  nameservers_ipv6 = var.nameservers_ipv6
  image            = data.hcloud_image.image.id
  server_type      = "cpx42"
  labels = {
    "cluster" = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  subnet_cidr     = var.subnet_cidr
  network_gateway = cidrhost(var.network_cidr, 1)
  ip_offset       = 5
  ignition_url    = var.bootstrap == true ? var.bootstrap_ignition_url : ""
}

module "master" {
  source           = "./modules/hcloud_coreos"
  instance_count   = var.replicas_master
  location         = var.location
  name             = "master"
  dns_domain       = var.dns_domain
  dns_zone_id      = var.dns_zone_id
  dns_records      = local.cloudflare_dns
  nameservers_ipv4 = var.nameservers_ipv4
  nameservers_ipv6 = var.nameservers_ipv6
  image            = data.hcloud_image.image.id
  server_type      = "cpx42"
  labels = {
    "${var.dns_domain}/master"  = "true",
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  subnet_cidr     = var.subnet_cidr
  network_gateway = cidrhost(var.network_cidr, 1)
  ip_offset       = 10
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/master"
  ignition_cacert = local.ignition_master_cacert
  volume_size     = var.master_volume_size

  # Resolvers cache negative answers, so api-int has to exist before the
  # nodes try to resolve it during their first boot.
  depends_on = [cloudflare_dns_record.dns_a_api_int]
}

module "worker" {
  source           = "./modules/hcloud_coreos"
  instance_count   = var.replicas_worker
  location         = var.location
  name             = "worker"
  dns_domain       = var.dns_domain
  dns_zone_id      = var.dns_zone_id
  dns_records      = local.cloudflare_dns
  nameservers_ipv4 = var.nameservers_ipv4
  nameservers_ipv6 = var.nameservers_ipv6
  image            = data.hcloud_image.image.id
  server_type      = "cpx42"
  labels = {
    "${var.dns_domain}/worker"  = "true"
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  subnet_cidr     = var.subnet_cidr
  network_gateway = cidrhost(var.network_cidr, 1)
  ip_offset       = 50
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert = local.ignition_worker_cacert
  volume_size     = var.worker_volume_size

  # Resolvers cache negative answers, so api-int has to exist before the
  # nodes try to resolve it during their first boot.
  depends_on = [cloudflare_dns_record.dns_a_api_int]
}
