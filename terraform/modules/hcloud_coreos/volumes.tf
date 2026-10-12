# Optional raw data volumes per instance, e.g. for the LVM Storage operator or
# Rook-Ceph. They are left unformatted on purpose, storage operators refuse
# devices that already carry a filesystem.
locals {
  data_volumes = merge([for i in range(var.instance_count) : {
    for j, size in var.volumes : format("%s%02d-data%d", var.name, i + 1, j + 1) => {
      instance = i
      name     = format("%s%02d.%s-data%d", var.name, i + 1, var.dns_domain, j + 1)
      size     = size
    }
  }]...)
}

# The volumes do not refer to the servers, so a server can be replaced
# (terraform apply -replace) and gets the same volumes attached again.
resource "hcloud_volume" "data" {
  for_each = local.data_volumes
  name     = each.value.name
  size     = each.value.size
  location = var.location
  labels   = var.labels
}

resource "hcloud_volume_attachment" "data" {
  for_each  = local.data_volumes
  volume_id = hcloud_volume.data[each.key].id
  server_id = hcloud_server.server[each.value.instance].id
  automount = false
}
