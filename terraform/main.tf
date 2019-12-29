module "bootstrap" {
  source         = "./modules/hcloud_instance"
  instance_count = 1
  name           = "master"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = var.hcloud_image
  user_data      = file("../ignition/bootstrap.ign")
}

module "master" {
  source         = "./modules/hcloud_instance"
  instance_count = 3
  name           = "master"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = var.hcloud_image
  user_data      = file("../ignition/master.ign")
}

module "worker" {
  source         = "./modules/hcloud_instance"
  instance_count = 3
  name           = "worker"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = var.hcloud_image
  user_data      = file("../ignition/worker.ign")
}
