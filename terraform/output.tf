output "bootstrap" {
  value = module.bootstrap
}
output "master" {
  value = module.master
}
output "worker" {
  value = module.worker
}

output "dns_records" {
  description = "DNS records required by the cluster"
  value       = [for r in local.dns_records : "${r.name} ${r.type} ${r.value}"]
}
