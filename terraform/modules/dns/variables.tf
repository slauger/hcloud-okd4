variable "provider_name" {
  type        = string
  description = "Provider that manages the records: cloudflare, hetzner or none"

  validation {
    condition     = contains(["cloudflare", "hetzner", "none"], var.provider_name)
    error_message = "provider_name must be cloudflare, hetzner or none."
  }
}

variable "records" {
  type = map(object({
    name  = string
    type  = string
    value = string
  }))
  description = "Records keyed by a static name, name is the fully qualified record name"
}

variable "ttl" {
  type        = number
  description = "TTL of the records"
  default     = 120
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Zone ID of the Cloudflare zone (only for cloudflare)"
  default     = null
}

variable "hetzner_zone" {
  type        = string
  description = "Name of the Hetzner DNS zone (only for hetzner)"
  default     = null
}
