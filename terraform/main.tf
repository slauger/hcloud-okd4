module "ignition" {
  source         = "./modules/hcloud_instance"
  instance_count = var.bootstrap == true ? 1 : 0
  location       = var.location
  name           = "ignition"
  dns_domain     = var.dns_domain
  dns_zone_id    = var.dns_zone_id
  image          = "ubuntu-22.04"
  user_data      = file("templates/cloud-init.tpl")
  ssh_keys       = data.hcloud_ssh_keys.all_keys.ssh_keys.*.name
  server_type    = "ccx13"
  subnet         = hcloud_network_subnet.subnet.id
}

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
  server_type     = "ccx23"
  subnet          = hcloud_network_subnet.subnet.id
  ignition_url    = var.bootstrap == true ? "http://${cloudflare_record.dns_a_ignition[0].name}/bootstrap.ign" : ""
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
  server_type     = "ccx23"
  labels          = {
    "okd.io/node" = "true",
    "okd.io/master" = "true",
    "okd.io/ingress" = "true"
  }
  # Manually add apply_to for the labels, until tf_hcloud allows apply_to in the firewall
  # firewall_ids    = [hcloud_firewall.okd-base.id, hcloud_firewall.okd-master.id, hcloud_firewall.okd-ingress.id]
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
  server_type     = "ccx23"
  labels          = {
    "okd.io/node" = "true",
    "okd.io/ingress" = "true"
    "okd.io/worker" = "true"
  }
  # Manually add apply_to for the labels, until tf_hcloud allows apply_to in the firewall
  # firewall_ids    = [hcloud_firewall.okd-base.id, hcloud_firewall.okd-ingress.id]
  subnet          = hcloud_network_subnet.subnet.id
  ignition_url    = "https://api-int.${var.dns_domain}:22623/config/worker"
  ignition_cacert = local.ignition_worker_cacert
}
