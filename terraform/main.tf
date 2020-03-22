module "bootstrap" {
  source         = "./modules/hcloud_instance"
  instance_count = var.bootstrap == true ? 1 : 0
  name           = "bootstrap"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = data.hcloud_image.bootstrap_image.id
  server_type    = "cx41"
}

module "master" {
  source         = "./modules/hcloud_instance"
  instance_count = var.replicas_master
  name           = "master"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = data.hcloud_image.image.id
  server_type    = "cx41"
  user_data      = file("../ignition/master.ign")
}

module "worker" {
  source         = "./modules/hcloud_instance"
  instance_count = var.replicas_worker
  name           = "worker"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = data.hcloud_image.image.id
  server_type    = "cx41"
  user_data      = file("../ignition/worker.ign")
}
