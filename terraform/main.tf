module "bootstrap" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.bootstrap == true ? 1 : 0
  location        = var.location
  name            = "bootstrap"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = false
  image           = data.hcloud_image.image.id
  image_name      = var.image
  server_type     = "cpx42"
  subnet          = hcloud_network_subnet.subnet.id
  ignition_url    = var.bootstrap == true ? var.bootstrap_ignition_url : ""
}

module "master" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.replicas_master
  location        = var.location
  name            = "master"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = false
  image           = data.hcloud_image.image.id
  image_name      = var.image
  server_type     = "cpx42"
  labels = {
    "${var.dns_domain}/master"  = "true",
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  subnet          = hcloud_network_subnet.subnet.id
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/master"
  ignition_cacert = local.ignition_master_cacert
}

module "worker" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.replicas_worker
  location        = var.location
  name            = "worker"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = false
  image           = data.hcloud_image.image.id
  image_name      = var.image
  server_type     = "cpx42"
  labels = {
    "${var.dns_domain}/worker"  = "true"
    "${var.dns_domain}/ingress" = "true"
    "cluster"                   = var.dns_domain
  }
  subnet          = hcloud_network_subnet.subnet.id
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert = local.ignition_worker_cacert
}
