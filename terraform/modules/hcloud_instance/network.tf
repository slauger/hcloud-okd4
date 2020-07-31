#resource "hcloud_server_network" "server_network" {
#  server_id = element(hcloud_server.server.*.id, count.index)
#  subnet_id = var.subnet
#  count = length(hcloud_server.server.*.id)
#}
