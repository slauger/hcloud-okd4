resource "cloudflare_load_balancer_pool" "bootstrap_pool" {
  name = "bootstrap-pool"

  dynamic "origins" {
    for_each = module.bootstrap.server_names
    content {
      name    = origins.value
      address = origins.value
    }
  }
  description = "OpenShift bootstrap node"
  count       = var.cloudflare_loadbalancing == true ? 1 : 0
}

resource "cloudflare_load_balancer_pool" "master_pool" {
  name = "master-pool"

  dynamic "origins" {
    for_each = module.master.server_names
    content {
      name    = origins.value
      address = origins.value
    }
  }
  description = "OpenShift master nodes"
  count       = var.cloudflare_loadbalancing == true ? 1 : 0
}

resource "cloudflare_load_balancer_pool" "worker_pool" {
  name = "worker-pool"

  dynamic "origins" {
    for_each = module.worker.server_names
    content {
      name    = origins.value
      address = origins.value
    }
  }
  description = "OpenShift worker nodes"
  count       = var.cloudflare_loadbalancing == true ? 1 : 0
}

