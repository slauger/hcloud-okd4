resource "cloudflare_load_balancer_monitor" "tcp_monitor_api" {
  type        = "tcp"
  method      = "connection_established"
  timeout     = 7
  interval    = 60
  retries     = 5
  port        = 6443
  description = "check-tcp-port-6443"
  count       = (var.cloudflare_loadbalancing == true && var.bootstrap == true) ? 1 : 0
}

resource "cloudflare_load_balancer_monitor" "tcp_monitor_apps" {
  type        = "tcp"
  method      = "connection_established"
  timeout     = 7
  interval    = 60
  retries     = 5
  port        = 443
  description = "check-tcp-port-443"
  count       = (var.cloudflare_loadbalancing == true && var.bootstrap == true) ? 1 : 0
}
