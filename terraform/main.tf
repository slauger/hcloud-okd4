locals {
  # Masters need 16 GB RAM. The image is built on cpx32 (160 GB disk) / cax21
  # (80 GB disk), server types with a smaller disk do not fit.
  server_type = coalesce(var.server_type, var.architecture == "arm" ? "cax31" : "cpx42")

  # Node names and private IPs are fixed, so their DNS records can be created
  # before the servers (dns.tf).
  nodes = {
    bootstrap = { count = var.bootstrap == true ? 1 : 0, ip_offset = 5 }
    master    = { count = var.replicas_master, ip_offset = 10 }
    worker    = { count = var.replicas_worker, ip_offset = 50 }
  }
}

module "bootstrap" {
  source           = "./modules/hcloud_coreos"
  instance_count   = local.nodes.bootstrap.count
  location         = var.location
  name             = "bootstrap"
  dns_domain       = var.dns_domain
  nameservers_ipv4 = var.nameservers_ipv4
  nameservers_ipv6 = var.nameservers_ipv6
  image            = local.image_id
  server_type      = coalesce(var.bootstrap_server_type, local.server_type)
  labels = {
    "cluster" = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  subnet_cidr     = var.subnet_cidr
  network_gateway = cidrhost(var.network_cidr, 1)
  ip_offset       = local.nodes.bootstrap.ip_offset
  ignition_url    = var.bootstrap == true ? var.bootstrap_ignition_url : ""
}

module "master" {
  source           = "./modules/hcloud_coreos"
  instance_count   = local.nodes.master.count
  location         = var.location
  name             = "master"
  dns_domain       = var.dns_domain
  nameservers_ipv4 = var.nameservers_ipv4
  nameservers_ipv6 = var.nameservers_ipv6
  image            = local.image_id
  server_type      = coalesce(var.master_server_type, local.server_type)
  labels = {
    "${var.dns_domain}/master"  = "true",
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  subnet_cidr     = var.subnet_cidr
  network_gateway = cidrhost(var.network_cidr, 1)
  ip_offset       = local.nodes.master.ip_offset
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/master"
  ignition_cacert = local.ignition_master_cacert
  volume_size     = var.master_volume_size

  # Resolvers cache negative answers, so api-int has to exist before the
  # nodes try to resolve it during their first boot.
  depends_on = [module.dns]
}

module "worker" {
  source           = "./modules/hcloud_coreos"
  instance_count   = local.nodes.worker.count
  location         = var.location
  name             = "worker"
  dns_domain       = var.dns_domain
  nameservers_ipv4 = var.nameservers_ipv4
  nameservers_ipv6 = var.nameservers_ipv6
  image            = local.image_id
  server_type      = coalesce(var.worker_server_type, local.server_type)
  labels = {
    "${var.dns_domain}/worker"  = "true"
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  network_id      = hcloud_network_subnet.subnet.network_id
  subnet_cidr     = var.subnet_cidr
  network_gateway = cidrhost(var.network_cidr, 1)
  ip_offset       = local.nodes.worker.ip_offset
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert = local.ignition_worker_cacert
  volume_size     = var.worker_volume_size

  # Resolvers cache negative answers, so api-int has to exist before the
  # nodes try to resolve it during their first boot.
  depends_on = [module.dns]
}
