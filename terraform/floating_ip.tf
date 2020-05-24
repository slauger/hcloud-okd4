resource "hcloud_floating_ip" "floating_ip" {
  type          = "ipv4"
  home_location = "nbg1"
}

#resource "hcloud_floating_ip_assignment" "main" {
#  floating_ip_id = hcloud_floating_ip.floating_ip.id
#  server_id      = module.haproxy.server_id[0]
#  count          = var.replicas_haproxy == 1 ? 1 : 0
#}
