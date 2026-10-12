output "records" {
  description = "Records in zone file notation"
  value       = [for r in values(var.records) : "${r.name} ${r.type} ${r.value}"]
}
