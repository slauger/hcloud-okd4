variable "name" {
  type        = string
  description = "Instance nam"
}

variable "dns_domain" {
  type        = string
  description = "DNS domain"
}

variable "dns_zone_id" {
  description = "Zone ID"
  default     = null
}

variable "dns_internal_ip" {
  description = "Point DNS record to internal ip"
  default     = false
}

variable "instance_count" {
  type        = number
  description = "Number of instances to deploy"
  default     = 1
}

variable "server_type" {
  type        = string
  description = "Hetzner Cloud instance type"
  default     = "cx11"
}

variable "image" {
  type        = string
  description = "Hetzner Cloud system image"
  default     = "ubuntu-22.04"
}

variable "ssh_keys" {
  type        = list(any)
  description = "SSH key IDs or names which should be injected into the server at creation time"
  default     = []
}

variable "keep_disk" {
  type        = bool
  description = "If true, do not upgrade the disk. This allows downgrading the server type later."
  default     = true
}

variable "location" {
  type        = string
  description = "The location name to create the server in. nbg1, fsn1 or hel1"
  default     = "nbg1"
}

variable "labels" {
  type        = map(string)
  description = "Labels that the instance is tagged with."
  default     = {}
}

variable "backups" {
  type        = bool
  description = "Enable or disable backups"
  default     = false
}

variable "firewall_ids" {
  type        = list(number)
  description = "Assigned firewalls"
  default     = []
}

variable "volume_size" {
  type        = number
  description = "Size in GB of an additional raw data volume per instance (0 = none)"
  default     = 0
}

variable "ignition_url" {
  type        = string
  description = "URL of the ignition config the instance merges on first boot"
}

variable "ignition_cacert" {
  type        = string
  description = "CA certificate for the machine config server"
  default     = ""
}

variable "network_id" {
  type        = string
  description = "Id of the private network the instance is attached to"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR of the private subnet the instance addresses are taken from"
}

variable "network_gateway" {
  type        = string
  description = "Gateway of the private network"
}

variable "public_interface" {
  type        = string
  description = "Name of the public network interface"
  default     = "enp1s0"
}

variable "nameservers_ipv4" {
  type        = list(string)
  description = "IPv4 resolvers configured on the nodes"
  default     = ["1.1.1.1", "1.0.0.1"]
}

variable "nameservers_ipv6" {
  type        = list(string)
  description = "IPv6 resolvers configured on the nodes"
  default     = ["2606:4700:4700::1111", "2606:4700:4700::1001"]
}

variable "private_interface" {
  type        = string
  description = "Name of the private network interface"
  default     = "enp7s0"
}

variable "ip_offset" {
  type        = number
  description = "Host number of the first instance address within the subnet"
}

variable "image_name" {
  type        = string
  description = "Either fcos or rhcos (necessary for ignition rendering)"
  default     = "fcos"
}

variable "ignition_version" {
  type        = string
  description = "Ignition Version"
  default     = "3.0.0"
}
