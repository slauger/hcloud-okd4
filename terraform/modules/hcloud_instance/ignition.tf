data "template_file" "ignition_config" {
  template = file("${path.module}/template.ign")
  vars = {
    hostname     = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}"
    hostname_b64 = base64encode("${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}")
    ignition_url = var.ignition_url
  }
  count = var.instance_count
}

#resource "local_file" "ignition_config" {
#  content  = data.template_file.ignition_config[count.index].rendered
#  filename = "${path.root}/${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}.ign"
#  count    = var.instance_count
#}
