variable "replicas_master" {
  type        = number
  default     = 1
  description = "Count of master replicas"
}

variable "replicas_worker" {
  type        = number
  default     = 0
  description = "Count of worker replicas"
}

variable "bootstrap" {
  type        = bool
  default     = false
  description = "Whether to deploy a bootstrap instance"
}

variable "bootstrap_ignition_url" {
  type        = string
  description = "Pre-signed URL of the bootstrap ignition config (set by make upload_ignition)"
  default     = ""
  sensitive   = true
}

variable "master_volume_size" {
  type        = number
  description = "Size in GB of an additional raw data volume per master node (0 = none)"
  default     = 0
}

variable "worker_volume_size" {
  type        = number
  description = "Size in GB of an additional raw data volume per worker node (0 = none)"
  default     = 0
}

variable "dns_domain" {
  type        = string
  description = "Name of the Cloudflare domain"
}

variable "dns_provider" {
  type        = string
  description = "Provider that manages the DNS records: cloudflare or none (bring your own DNS)"
  default     = "cloudflare"

  validation {
    condition     = contains(["cloudflare", "none"], var.dns_provider)
    error_message = "dns_provider must be either cloudflare or none."
  }
}

variable "nameservers_ipv4" {
  type        = list(string)
  description = "IPv4 resolvers configured on the nodes (keep in sync with NAMESERVERS of the image build)"
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "nameservers_ipv6" {
  type        = list(string)
  description = "IPv6 resolvers configured on the nodes (libc uses at most three resolvers in total)"
  default     = ["2606:4700:4700::1111"]
}

variable "dns_zone_id" {
  type        = string
  description = "Zone ID of the Cloudflare domain (only for dns_provider = cloudflare)"
  default     = null
}

variable "ip_loadbalancer_api" {
  description = "IP of an external loadbalancer for api (optional)"
  default     = null
}

variable "ip_loadbalancer_api_int" {
  description = "IP of an external loadbalancer for api-int (optional)"
  default     = null
}

variable "ip_loadbalancer_apps" {
  description = "IP of an external loadbalancer for apps (optional)"
  default     = null
}

variable "network_cidr" {
  type        = string
  description = "CIDR for the network"
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR for the subnet"
  default     = "192.168.254.0/24"
}

variable "lb_subnet_cidr" {
  type        = string
  description = "CIDR for the loadbalancer subnet"
  default     = "192.168.253.0/24"
}

variable "location" {
  type        = string
  description = "Region"
  default     = "nbg1"
}

variable "image" {
  type        = string
  description = "Image selector (either fcos or rhcos)"
  default     = "fcos"
}
