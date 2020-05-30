module "ignition" {
  source         = "./modules/hcloud_instance"
  instance_count  = var.bootstrap == true ? 1 : 0
  name           = "ignition"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = "ubuntu-20.04"
  user_data       = file("templates/cloud-init.tpl")
  ssh_keys       = data.hcloud_ssh_keys.all_keys.ssh_keys.*.name
  server_type    = "cx11"
  subnet         = hcloud_network.network.id
}

module "bootstrap" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.bootstrap == true ? 1 : 0
  name            = "bootstrap"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = true
  image           = data.hcloud_image.image.id
  server_type     = "cx41"
  subnet          = hcloud_network.network.id
  ignition_url    = "http://ignition.${var.dns_domain}/bootstrap.ign"
}

module "master" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.replicas_master
  name            = "master"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = true
  image           = data.hcloud_image.image.id
  server_type     = "cx41"
  subnet          = hcloud_network.network.id
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/master"
  ignition_cacert = local.ignition_master_cacert
}

module "worker" {
  source          = "./modules/hcloud_coreos"
  instance_count  = var.replicas_worker
  name            = "worker"
  dns_domain      = var.dns_domain
  dns_zone_id     = var.dns_zone_id
  dns_internal_ip = true
  image           = data.hcloud_image.image.id
  server_type     = "cx41"
  subnet          = hcloud_network.network.id
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert = local.ignition_worker_cacert
}

module "haproxy" {
  source         = "./modules/hcloud_instance"
  instance_count = var.replicas_haproxy
  name           = "lb"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = "ubuntu-20.04"
  user_data       = file("templates/cloud-init.tpl")
  ssh_keys       = data.hcloud_ssh_keys.all_keys.ssh_keys.*.name
  server_type    = "cx11"
  subnet         = hcloud_network.network.id
}
