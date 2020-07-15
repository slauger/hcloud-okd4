resource "hcloud_load_balancer" "lbext" {
  name               = "lbext.${var.dns_domain}"
  load_balancer_type = "lb11"
  location           = var.location
  dynamic "target" {
    for_each = concat(module.master.server_ids, module.worker.server_ids)
    content {
        type = "server"
        server_id = target.value
    }
  }
}

resource "hcloud_load_balancer_network" "lbext_network" {
  load_balancer_id = hcloud_load_balancer.lbext.id
  network_id = hcloud_network.network.id
  ip = "192.168.254.254"
}

resource "hcloud_load_balancer_service" "lbext_api" {
  load_balancer_id = hcloud_load_balancer.lbext.id
  protocol = "tcp"
  listen_port = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port = 6443
    interval = 10
    timeout = 1
    retries = 3
  }
}

resource "hcloud_load_balancer_service" "lbext_ingress_http" {
  load_balancer_id = hcloud_load_balancer.lbext.id
  protocol = "tcp"
  listen_port = 80
  destination_port = 80

  health_check {
    protocol = "tcp"
    port = 80
    interval = 10
    timeout = 1
    retries = 3
  }
}

resource "hcloud_load_balancer_service" "lbext_ingress_https" {
  load_balancer_id = hcloud_load_balancer.lbext.id
  protocol = "tcp"
  listen_port = 443
  destination_port = 443

  health_check {
    protocol = "tcp"
    port = 443
    interval = 10
    timeout = 1
    retries = 3
  }
}

resource "hcloud_load_balancer" "lbint" {
  name               = "lbint.${var.dns_domain}"
  load_balancer_type = "lb11"
  location           = var.location

  dynamic "target" {
    for_each = concat(module.master.server_ids, module.worker.server_ids)
    content {
        type = "server"
        server_id = target.value
    }
  }
}

resource "hcloud_load_balancer_network" "lbint_network" {
  load_balancer_id = hcloud_load_balancer.lbint.id
  network_id = hcloud_network.network.id
  ip = "192.168.254.253"
  enable_public_interface = false
}

resource "hcloud_load_balancer_service" "lbint_api" {
  load_balancer_id = hcloud_load_balancer.lbint.id
  protocol = "tcp"
  listen_port = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port = 6443
    interval = 10
    timeout = 1
    retries = 3
  }
}

resource "hcloud_load_balancer_service" "lbint_ingress_mcs" {
  load_balancer_id = hcloud_load_balancer.lbint.id
  protocol = "tcp"
  listen_port = 22623
  destination_port = 22623

  health_check {
    protocol = "tcp"
    port = 22623
    interval = 10
    timeout = 1
    retries = 3
  }
}

#resource "hcloud_load_balancer_service" "lbint_ingress_http" {
#  load_balancer_id = hcloud_load_balancer.lbint.id
#  protocol = "tcp"
#  listen_port = 80
#  destination_port = 80
#
#  health_check {
#    protocol = "tcp"
#    port = 80
#    interval = 10
#    timeout = 1
#    retries = 3
#  }
#}

#resource "hcloud_load_balancer_service" "lbint_ingress_https" {
#  load_balancer_id = hcloud_load_balancer.lbint.id
#  protocol = "tcp"
#  listen_port = 443
#  destination_port = 443
#
#  health_check {
#    protocol = "tcp"
#    port = 443
#    interval = 10
#    timeout = 1
#    retries = 3
#  }
#}
