# required for the upload to the ignition host
resource "local_file" "ignition_config" {
  count = var.instance_count

  content = templatefile("${path.module}/templates/ignition.ign", {
    hostname         = format("%s%02d.%s", var.name, count.index + 1, var.dns_domain)
    hostname_b64     = base64encode(format("%s%02d.%s", var.name, count.index + 1, var.dns_domain))
    resolvconf_b64   = base64encode(file("${path.module}/templates/resolv.conf"))
    ignition_url     = var.ignition_url
    ignition_version = var.ignition_version
    ignition_cacert  = var.ignition_cacert
  })

  filename = "${path.root}/../ignition/${format("%s%02d.%s", var.name, count.index + 1, var.dns_domain)}.ign"
}
