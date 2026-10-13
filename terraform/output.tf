output "bootstrap" {
  value = module.bootstrap
}
output "master" {
  value = module.master
}
output "node_pools" {
  value = module.pool
}

output "data_volumes" {
  description = "Device paths of the data volumes per node"
  value       = merge(module.master.data_volumes, [for m in module.pool : m.data_volumes]...)
}

# Read by make label_nodes
output "node_config" {
  description = "Kubernetes role, labels and taints per worker node"
  value = merge([for name, pool in local.node_pools : {
    for node in module.pool[name].server_names : node => {
      labels = merge(
        { "node-role.kubernetes.io/${name}" = "" },
        # nodePlacement of the IngressController, see docs/node-pools.md
        pool.ingress ? { "${var.dns_domain}/ingress" = "true" } : {},
        pool.labels
      )
      taints = pool.taints
    }
  }]...)
}

output "dns_records" {
  description = "DNS records required by the cluster"
  value       = module.dns.records
}
