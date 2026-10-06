# rendered pointer configs, kept for debugging. The bootstrap config contains
# the pre-signed URL of the bootstrap ignition config, so keep it private.
resource "local_file" "ignition_config" {
  count           = var.instance_count
  file_permission = "0600"

  content = templatefile("${path.module}/templates/ignition.ign", {
    hostname         = format("%s%02d.%s", var.name, count.index + 1, var.dns_domain)
    hostname_b64     = base64encode(format("%s%02d.%s", var.name, count.index + 1, var.dns_domain))
    ignition_url     = var.ignition_url
    ignition_version = var.ignition_version
    ignition_cacert  = var.ignition_cacert
    nodeip_hint      = cidrhost(var.subnet_cidr, 0)
    private_nm_b64   = base64encode(local.private_nmconnection[count.index])
    public_nm_b64    = base64encode(local.public_nmconnection[count.index])
  })

  filename = "${path.root}/../ignition/${format("%s%02d.%s", var.name, count.index + 1, var.dns_domain)}.ign"
}
