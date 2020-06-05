resource "hcloud_network" "network" {
  name     = var.dns_domain
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = var.subnet_cidr
}
