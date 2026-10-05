output "server_ids" {
  value = hcloud_server.server.*.id
}

output "server_names" {
  value = hcloud_server.server.*.name
}

output "internal_ipv4_addresses" {
  value = local.private_ipv4_addresses
}

output "ipv4_addresses" {
  value = hcloud_server.server.*.ipv4_address
}

output "ipv6_addresses" {
  value = hcloud_server.server.*.ipv6_address
}
