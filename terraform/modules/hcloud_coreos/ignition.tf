data "template_file" "network_cfg_eth0" {
  template = file("${path.module}/network.cfg")
  interface = "eth0"
  bootproto = "dhcp"
  peerdns = "yes"
}

data "template_file" "network_cfg_eth1" {
  template = file("${path.module}/network.cfg")
  interface = "eth1"
  bootproto = "dhcp"
  peerdns = "no"
}

data "template_file" "ignition_config" {
  template = file("${path.module}/template.ign")
  vars = {
    hostname         = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}"
    hostname_b64     = base64encode("${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}")
    ignition_url     = var.ignition_url
    ignition_cacert  = var.ignition_cacert
    network_cfg_eth0 = base64encode(data.template_file.network_cfg_eth0.rendered)
    network_cfg_eth1 = base64encode(data.template_file.network_cfg_eth1.rendered)
  }
  count = var.instance_count
}

resource "local_file" "ignition_config" {
  content  = data.template_file.ignition_config[count.index].rendered
  filename = "${path.root}/${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}.ign"
  count    = var.instance_count
}
