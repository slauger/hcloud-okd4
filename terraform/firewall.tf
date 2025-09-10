# https://docs.okd.io/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-network-connectivity-user-infra_installing-platform-agnostic
resource "hcloud_firewall" "base" {
  name = "${var.dns_domain}-base"
  # ICMP is always a good idea
  #
  # Network reachability tests
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  # Metrics
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 1936
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # Host level services, including the node exporter on ports 9100-9101 and the Cluster Version Operator on port 9099.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "9000-9999"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # The default ports that Kubernetes reserves
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "10250-10259"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # openshift-sdn
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "10256"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # VXLAN and Geneve
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "4789"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # VXLAN and Geneve
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "6081"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # Host level services, including the node exporter on ports 9100-9101.
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "9000-9999"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # Kubernetes node port
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "30000-32767"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # Kubernetes node port
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "30000-32767"
    source_ips = [for s in concat(module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
}


resource "hcloud_firewall" "master" {
  name = "${var.dns_domain}-master"

  # ICMP is always a good idea
  #
  # Network reachability tests
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  # Kubernetes API
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [for s in concat([hcloud_load_balancer.lb.ipv4], module.master.ipv4_addresses, module.worker.ipv4_addresses, module.bootstrap.ipv4_addresses) : "${s}/32"]
  }
  # Machine config server
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22623"
    source_ips = [for s in concat([hcloud_load_balancer.lb.ipv4]) : "${s}/32"]
  }
  # etcd server and peer ports
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "2379-2380"
    source_ips = [for s in module.master.ipv4_addresses : "${s}/32"]
  }
}

resource "hcloud_firewall" "ingress" {
  name = "${var.dns_domain}-ingress"

  # ICMP is always a good idea
  #
  # Network reachability tests
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = [for s in [hcloud_load_balancer.lb.ipv4] : "${s}/32"]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = [for s in [hcloud_load_balancer.lb.ipv4] : "${s}/32"]
  }
}

resource "hcloud_firewall_attachment" "base" {
  firewall_id     = hcloud_firewall.base.id
  label_selectors = ["${var.dns_domain}/master=true", "${var.dns_domain}/worker=true"]
}

resource "hcloud_firewall_attachment" "master" {
  firewall_id     = hcloud_firewall.master.id
  label_selectors = ["${var.dns_domain}/master=true"]
}

resource "hcloud_firewall_attachment" "ingress" {
  firewall_id     = hcloud_firewall.ingress.id
  label_selectors = ["${var.dns_domain}/ingress=true"]
}
