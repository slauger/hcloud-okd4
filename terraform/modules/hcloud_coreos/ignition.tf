data "template_file" "configure_script" {
  template = file("${path.module}/hcloud-firstboot.sh")
  vars = {
    hostname = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}"
    domain   = "${var.dns_domain}"
  }
}

data "template_file" "ignition_config" {
  template = file("${path.module}/template.ign")
  vars = {
    ignition_url     = var.ignition_url
    ignition_cacert  = var.ignition_cacert
    configure_script = base64encode(data.template_file.configure_sh.rendered)
  }
  count = var.instance_count
}

resource "local_file" "ignition_config" {
  content  = data.template_file.ignition_config[count.index].rendered
  filename = "${path.root}/${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}.ign"
  count    = var.instance_count
}
