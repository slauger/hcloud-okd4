output "server_ids" {
  value = hcloud_server.server[*].id
}

output "server_names" {
  value = hcloud_server.server[*].name
}

output "internal_ipv4_addresses" {
  value = local.private_ipv4_addresses
}

output "ipv4_addresses" {
  value = hcloud_server.server[*].ipv4_address
}

output "ipv6_addresses" {
  value = hcloud_server.server[*].ipv6_address
}

output "data_volumes" {
  description = "Device paths of the data volumes per instance"
  value = {
    for i, name in hcloud_server.server[*].name : name => [
      for j in range(length(var.volumes)) : hcloud_volume.data[format("%s%02d-data%d", var.name, i + 1, j + 1)].linux_device
    ]
  }
}
