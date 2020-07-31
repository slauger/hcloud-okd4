resource "hcloud_load_balancer" "lb" {
  name               = "lb.${var.dns_domain}"
  load_balancer_type = "lb11"
  location           = var.location
  dynamic "target" {
    for_each = concat(module.master.server_ids, module.worker.server_ids, module.bootstrap.server_ids)
    content {
      type      = "server"
      server_id = target.value
    }
  }
}

resource "hcloud_load_balancer_network" "lb_network" {
  load_balancer_id = hcloud_load_balancer.lb.id
  subnet_id        = hcloud_network_subnet.lb_subnet.id
  ip               = "192.168.254.254"
}

resource "hcloud_load_balancer_service" "lb_api" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 1
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "lb_mcs" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 22623
  destination_port = 22623

  health_check {
    protocol = "tcp"
    port     = 22623
    interval = 10
    timeout  = 1
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "lb_ingress_http" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80

  health_check {
    protocol = "tcp"
    port     = 80
    interval = 10
    timeout  = 1
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "lb_ingress_https" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443

  health_check {
    protocol = "tcp"
    port     = 443
    interval = 10
    timeout  = 1
    retries  = 3
  }
}
