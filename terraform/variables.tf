variable "replicas_master" {
  type        = number
  default     = 3
  description = "Count of master replicas"
}

variable "replicas_worker" {
  type        = number
  default     = 3
  description = "Count of worker replicas"
}

variable "bootstrap" {
  type        = bool
  default     = false
  description = "Whether to deploy a bootstrap instance"
}

variable "dns_domain" {
  type        = string
  description = "Name of the Cloudflare domain"
}

variable "dns_zone_id" {
  type        = string
  description = "Zone ID of the Cloudflare domain"
}

variable "ip_loadbalancer_api" {
  type        = string
  description = "IP of an external loadbalancer for api (optional)"
  default     = ""
}

variable "ip_loadbalancer_api_int" {
  type        = string
  description = "IP of an external loadbalancer for api-int (optional)"
  default     = ""
}

variable "ip_loadbalancer_apps" {
  type        = string
  description = "IP of an external loadbalancer for apps (optional)"
  default     = ""
}

variable "cloudflare_loadbalancing" {
  type        = bool
  description = "Whether to use a Cloudflare loadbalancer"
  default     = true
}

variable "ignition_baseurl" {
  type = string
  description = "Base URL to the external ignition webserver"
}

variable "network_cidr" {
  type = string
  description = "CIDR for the network"
  default = "192.168.0.0/16"
}

variable "subnet_cidr" {
  type = string
  description = "CIDR for the subnet"
  default = "192.168.254.0/24"
}
