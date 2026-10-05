# Cluster traffic uses the private network, which is not filtered by hcloud
# firewalls. The load balancer reaches its targets via their private IPs as well,
# so the public interfaces of the nodes do not need to accept anything but ICMP.
resource "hcloud_firewall" "nodes" {
  name = "${var.dns_domain}-nodes"

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  apply_to {
    label_selector = "cluster=${var.dns_domain}"
  }
}
