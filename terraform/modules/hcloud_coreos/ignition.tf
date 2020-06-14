resource "random_uuid" "eth0" {
  count = var.instance_count
}
resource "random_uuid" "eth1" {
  count = var.instance_count
}

# /etc/sysconfig/network-scripts/ifcg-eth0
data "template_file" "network_cfg_eth0" {
  template = file("${path.module}/templates/network.cfg")
  vars = {
    interface = "eth0"
    bootproto = "dhcp"
    peerdns = "yes"
  }
}

# /etc/sysconfig/network-scripts/ifcg-eth1
data "template_file" "network_cfg_eth1" {
  template = file("${path.module}/templates/network.cfg")
  vars = {
    interface = "eth1"
    peerdns = "no"
  }
}

# /etc/NetworkManager/system-connections/Wired\ connection\ 1.nmconnection
data "template_file" "networkmanager_cfg_eth0" {
  template = file("${path.module}/templates/networkmanager.cfg")
  vars = {
    name = "Wired connection 1"
    uuid = random_uuid.eth0[count.index].result
    interface = "eth0"
    domain = var.dns_domain
  }
  count = var.instance_count
}

# /etc/NetworkManager/system-connections/Wired\ connection\ 2.nmconnection
data "template_file" "networkmanager_cfg_eth1" {
  template = file("${path.module}/templates/networkmanager.cfg")
  vars = {
    name = "Wired connection 2"
    uuid = random_uuid.eth1[count.index].result
    interface = "eth1"
    domain = var.dns_domain
  }
  count = var.instance_count
}


#data "template_file" "configure_script" {
#  template = file("${path.module}/hcloud-firstboot.sh")
#  vars = {
#    hostname = "${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}"
#    domain   = "${var.dns_domain}"
#  }
#  count = var.instance_count
#}

data "template_file" "ignition_config" {
  template = file("${path.module}/templates/ignition.ign")
  vars = {
    ignition_url     = var.ignition_url
    ignition_cacert  = var.ignition_cacert
    #configure_script = base64encode(data.template_file.configure_script[count.index].rendered)
    network_cfg_eth0 = base64encode(data.template_file.network_cfg_eth0.rendered)
    network_cfg_eth1 = base64encode(data.template_file.network_cfg_eth1.rendered)
    networkmanager_cfg_eth0 = base64encode(data.template_file.networkmanager_cfg_eth0[count.index].rendered)
    networkmanager_cfg_eth1 = base64encode(data.template_file.networkmanager_cfg_eth1[count.index].rendered)
  }
  count = var.instance_count
}

resource "local_file" "ignition_config" {
  content  = data.template_file.ignition_config[count.index].rendered
  filename = "${path.root}/${format("${var.name}%02d", count.index + 1)}.${var.dns_domain}.ign"
  count    = var.instance_count
}
