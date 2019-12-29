variable "hcloud_image" {
  description = "Name of the hcloud image"
}

variable "replicas_master" {
  default     = 3
  description = "Count of master replicas"
}

variable "replicas_worker" {
  default     = 3
  description = "Count of worker replicas"
}

variable "bootstrap_enable" {
  default     = false
  description = "Whether to deploy a bootstrap instance"
}

variable "dns_domain" {
  description = "Name of the Cloudflare domain"
}

variable "dns_zone_id" {
  description = "Zone ID of the Cloudflare domain"
}

variable "ip_loadbalancer_api" {
  description = "IP of an external loadbalancer for api (optional)"
  default = ""
}

variable "ip_loadbalancer_api_int" {
  description = "IP of an external loadbalancer for api-int (optional)"
  default = ""
}

variable "ip_loadbalancer_apps" {
  description = "IP of an external loadbalancer for apps (optional)"
  default = ""
}
