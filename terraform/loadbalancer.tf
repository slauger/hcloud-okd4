locals {
  # Services of a Hetzner load balancer listen on all of its interfaces, so the
  # machine config server (22623) must not be served by the public one. It hands
  # out the node configuration including the bootstrap credentials.
  lb_public_ports   = { api = 6443, http = 80, https = 443 }
  lb_internal_ports = { api = 6443, mcs = 22623 }

  # Targets are keyed by server name, so scaling one role does not shift the
  # targets of the others.
  control_plane_servers = merge([for m in [module.bootstrap, module.master] : zipmap(m.server_names, m.server_ids)]...)
  all_servers           = merge([for m in [module.bootstrap, module.master, module.worker] : zipmap(m.server_names, m.server_ids)]...)
}

# Public load balancer: API and ingress
resource "hcloud_load_balancer" "lb" {
  name               = "lb.${var.dns_domain}"
  load_balancer_type = var.load_balancer_type
  location           = var.location
}

resource "hcloud_load_balancer_network" "lb_network" {
  load_balancer_id = hcloud_load_balancer.lb.id
  subnet_id        = hcloud_network_subnet.lb_subnet.id
  ip               = cidrhost(var.lb_subnet_cidr, -3)
}

resource "hcloud_load_balancer_target" "nodes" {
  for_each         = local.all_servers
  type             = "server"
  load_balancer_id = hcloud_load_balancer.lb.id
  server_id        = each.value
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.lb_network]
}

resource "hcloud_load_balancer_service" "public" {
  for_each         = local.lb_public_ports
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = each.value
  destination_port = each.value

  # The API is checked via /readyz, an API server that is starting or shutting
  # down still accepts TCP connections, but must not receive requests.
  health_check {
    protocol = each.key == "api" ? "http" : "tcp"
    port     = each.value
    interval = 10
    timeout  = 5
    retries  = 3

    dynamic "http" {
      for_each = each.key == "api" ? [1] : []
      content {
        path         = "/readyz"
        tls          = true
        status_codes = ["200"]
      }
    }
  }
}

# Internal load balancer: API and machine config server for the nodes (api-int)
resource "hcloud_load_balancer" "internal" {
  name               = "lb-int.${var.dns_domain}"
  load_balancer_type = var.load_balancer_type
  location           = var.location
}

resource "hcloud_load_balancer_network" "internal" {
  load_balancer_id        = hcloud_load_balancer.internal.id
  subnet_id               = hcloud_network_subnet.lb_subnet.id
  ip                      = cidrhost(var.lb_subnet_cidr, -2)
  enable_public_interface = false
}

resource "hcloud_load_balancer_target" "control_plane" {
  for_each         = local.control_plane_servers
  type             = "server"
  load_balancer_id = hcloud_load_balancer.internal.id
  server_id        = each.value
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.internal]
}

resource "hcloud_load_balancer_service" "internal" {
  for_each         = local.lb_internal_ports
  load_balancer_id = hcloud_load_balancer.internal.id
  protocol         = "tcp"
  listen_port      = each.value
  destination_port = each.value

  # The API is checked via /readyz, an API server that is starting or shutting
  # down still accepts TCP connections, but must not receive requests.
  health_check {
    protocol = each.key == "api" ? "http" : "tcp"
    port     = each.value
    interval = 10
    timeout  = 5
    retries  = 3

    dynamic "http" {
      for_each = each.key == "api" ? [1] : []
      content {
        path         = "/readyz"
        tls          = true
        status_codes = ["200"]
      }
    }
  }
}

moved {
  from = hcloud_load_balancer_service.lb_api
  to   = hcloud_load_balancer_service.public["api"]
}

moved {
  from = hcloud_load_balancer_service.lb_ingress_http
  to   = hcloud_load_balancer_service.public["http"]
}

moved {
  from = hcloud_load_balancer_service.lb_ingress_https
  to   = hcloud_load_balancer_service.public["https"]
}
