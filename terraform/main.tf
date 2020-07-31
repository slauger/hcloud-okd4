module "ignition" {
  source         = "./modules/hcloud_instance"
  instance_count = var.bootstrap == true ? 1 : 0
  location       = var.location
  name           = "ignition"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = "ubuntu-20.04"
  user_data      = file("templates/cloud-init.tpl")
  ssh_keys       = data.hcloud_ssh_keys.all_keys.ssh_keys.*.name
  server_type    = "cx11"
  subnet         = hcloud_network_subnet.subnet.id
}

module "bootstrap" {
  source           = "./modules/hcloud_coreos"
  instance_count   = var.bootstrap == true ? 1 : 0
  location         = var.location
  name             = "bootstrap"
  dns_domain       = var.dns_domain
  dns_zone_id      = var.dns_zone_id
  dns_internal_ip  = false
  image            = data.hcloud_image.image.id
  image_name       = var.image
  server_type      = "cx41"
  subnet           = hcloud_network_subnet.subnet.id
  ignition_url     = var.bootstrap == true ? "http://${cloudflare_record.dns_a_ignition[0].name}/bootstrap.ign" : ""
  ignition_version = var.image == "fcos" ? "3.0.0" : "2.2.0"
}

module "master" {
  source           = "./modules/hcloud_coreos"
  instance_count   = var.replicas_master
  location         = var.location
  name             = "master"
  dns_domain       = var.dns_domain
  dns_zone_id      = var.dns_zone_id
  dns_internal_ip  = false
  image            = data.hcloud_image.image.id
  image_name       = var.image
  server_type      = "cx41"
  subnet           = hcloud_network_subnet.subnet.id
  ignition_url     = "https://api-int.${var.dns_domain}:22623/config/master"
  ignition_cacert  = local.ignition_master_cacert
  ignition_version = var.image == "fcos" ? "3.0.0" : "2.2.0"
}

module "worker" {
  source           = "./modules/hcloud_coreos"
  instance_count   = var.replicas_worker
  location         = var.location
  name             = "worker"
  dns_domain       = var.dns_domain
  dns_zone_id      = var.dns_zone_id
  dns_internal_ip  = false
  image            = data.hcloud_image.image.id
  image_name       = var.image
  server_type      = "cx41"
  subnet           = hcloud_network_subnet.subnet.id
  ignition_url     = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert  = local.ignition_worker_cacert
  ignition_version = var.image == "fcos" ? "3.0.0" : "2.2.0"
}
