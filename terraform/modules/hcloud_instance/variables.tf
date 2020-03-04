variable "name" {
  description = "Instance nam"
}

variable "dns_domain" {
  description = "DNS domain"
}

variable "dns_zone_id" {
  description = "Zone ID"
  default     = null
}

variable "instance_count" {
  description = "Number of instances to deploy"
  default     = 1
}

variable "server_type" {
  description = "Hetzner Cloud instance type"
  default     = "cx11"
}

variable "image" {
  description = "Hetzner Cloud system image"
  default     = "ubuntu-18.04"
}

variable "user_data" {
  description = "Cloud-Init user data to use during server creation"
  default     = "echo provisioned > /var/log/provisioned.log"
}

variable "ssh_keys" {
  description = "SSH key IDs or names which should be injected into the server at creation time"
  default     = []
}

variable "keep_disk" {
  description = "If true, do not upgrade the disk. This allows downgrading the server type later."
  default     = true
}

variable "location" {
  description = "The location name to create the server in. nbg1, fsn1 or hel1"
  default     = "nbg1"
}

variable "backups" {
  description = "Enable or disable backups"
  default     = false
}

variable "volume" {
  description = "Enable or disable an additional volume"
  default     = false
}

variable "volume_size" {
  description = "Size of the additional data volume"
  default     = 20
}
