# Optional raw data volume per instance, e.g. for the LVM Storage operator or
# Rook-Ceph. It is left unformatted on purpose, storage operators refuse
# devices that already carry a filesystem.
resource "hcloud_volume" "volumes" {
  count     = var.volume_size > 0 ? var.instance_count : 0
  name      = "${hcloud_server.server[count.index].name}-data"
  size      = var.volume_size
  automount = false
  server_id = hcloud_server.server[count.index].id
  labels    = var.labels
}
