variable "replicas_master" {
  type        = number
  default     = 1
  description = "Count of master replicas"
}

variable "replicas_worker" {
  type        = number
  default     = 0
  description = "Count of worker replicas (only without node_pools)"
}

variable "node_pools" {
  type = map(object({
    count       = number
    ip_offset   = number
    server_type = optional(string)
    volumes     = optional(list(number), [])
    ingress     = optional(bool, false)
    labels      = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
  }))
  description = "Worker node pools, keyed by pool name. Without node_pools, replicas_worker, worker_server_type and worker_volume_size form a single pool worker."
  default     = null

  # coalesce, || does not short-circuit before Terraform 1.12
  validation {
    condition     = alltrue([for name, p in coalesce(var.node_pools, {}) : can(regex("^[a-z]([a-z0-9-]{0,18}[a-z])?$", name)) && !contains(["bootstrap", "master", "control-plane"], name)])
    error_message = "Pool names must start and end with a lowercase letter, contain only lowercase letters, digits and dashes (max. 20 characters), and must not be bootstrap, master or control-plane."
  }

  validation {
    condition     = alltrue([for p in values(coalesce(var.node_pools, {})) : p.count >= 0 && floor(p.count) == p.count && floor(p.ip_offset) == p.ip_offset && p.ip_offset >= 10 + var.replicas_master])
    error_message = "count and ip_offset of a pool must be whole numbers, count must not be negative, and ip_offset has to be above the masters (10 + replicas_master), e.g. 50."
  }

  validation {
    condition = alltrue([for a, pa in coalesce(var.node_pools, {}) : alltrue([
      for b, pb in coalesce(var.node_pools, {}) : a == b || pa.count == 0 || pb.count == 0 || pa.ip_offset + pa.count <= pb.ip_offset || pb.ip_offset + pb.count <= pa.ip_offset
    ])])
    error_message = "The address ranges of the pools (ip_offset to ip_offset + count - 1) must not overlap."
  }

  validation {
    condition     = alltrue([for p in values(coalesce(var.node_pools, {})) : p.ip_offset + p.count <= pow(2, 32 - try(tonumber(split("/", var.subnet_cidr)[1]), 32)) - 1])
    error_message = "The address range of a pool (ip_offset to ip_offset + count - 1) has to fit into subnet_cidr, use a larger subnet_cidr for more nodes."
  }

  validation {
    condition     = alltrue([for p in values(coalesce(var.node_pools, {})) : length(p.volumes) <= 16 && alltrue([for v in p.volumes : v >= 10 && v <= 10240])])
    error_message = "Hetzner supports at most 16 volumes per server with 10 to 10240 GB each."
  }

  validation {
    condition     = alltrue(flatten([for p in values(coalesce(var.node_pools, {})) : [for t in p.taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], t.effect)]]))
    error_message = "The effect of a taint must be NoSchedule, PreferNoSchedule or NoExecute."
  }
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

variable "master_volumes" {
  type        = list(number)
  description = "Sizes in GB of additional raw data volumes per master node"
  default     = []

  validation {
    condition     = length(var.master_volumes) <= 16 && alltrue([for v in var.master_volumes : v >= 10 && v <= 10240])
    error_message = "Hetzner supports at most 16 volumes per server with 10 to 10240 GB each."
  }
}

variable "master_volume_size" {
  type        = number
  description = "Size in GB of one additional raw data volume per master node (0 = none), master_volumes takes precedence"
  default     = 0
}

variable "worker_volume_size" {
  type        = number
  description = "Size in GB of one additional raw data volume per worker node (0 = none, only without node_pools)"
  default     = 0
}

variable "dns_domain" {
  type        = string
  description = "Cluster domain (metadata.name and baseDomain of install-config.yaml)"
}

variable "dns_provider" {
  type        = string
  description = "Provider that manages the DNS records: cloudflare, hetzner or none (bring your own DNS)"
  default     = "cloudflare"

  validation {
    condition     = contains(["cloudflare", "hetzner", "none"], var.dns_provider)
    error_message = "dns_provider must be cloudflare, hetzner or none."
  }
}

variable "dns_zone" {
  type        = string
  description = "Name of the Hetzner DNS zone (only for dns_provider = hetzner), defaults to the cluster domain without its first label (baseDomain)"
  default     = null
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

variable "network_cidr" {
  type        = string
  description = "CIDR for the network"
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR for the subnet"
  default     = "192.168.254.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0)) && strcontains(var.subnet_cidr, "/")
    error_message = "subnet_cidr must be an IPv4 CIDR, e.g. 192.168.254.0/24."
  }
}

variable "lb_subnet_cidr" {
  type        = string
  description = "CIDR for the loadbalancer subnet"
  default     = "192.168.253.0/24"
}

variable "location" {
  type        = string
  description = "Location of the servers and load balancers"
  default     = "nbg1"
}

variable "network_zone" {
  type        = string
  description = "Network zone of the private network, has to contain the location (eu-central, us-east, us-west or ap-southeast)"
  default     = "eu-central"
}

variable "load_balancer_type" {
  type        = string
  description = "Type of the public and the internal load balancer"
  default     = "lb11"
}

variable "architecture" {
  type        = string
  description = "CPU architecture of the nodes: x86 or arm (Hetzner CAX servers)"
  default     = "x86"

  validation {
    condition     = contains(["x86", "arm"], var.architecture)
    error_message = "architecture must be either x86 or arm."
  }
}

variable "server_type" {
  type        = string
  description = "Server type of all nodes (default: cpx42 for x86, cax31 for arm)"
  default     = null
}

variable "bootstrap_server_type" {
  type        = string
  description = "Server type of the bootstrap node (default: server_type)"
  default     = null
}

variable "master_server_type" {
  type        = string
  description = "Server type of the master nodes (default: server_type)"
  default     = null
}

variable "worker_server_type" {
  type        = string
  description = "Server type of the worker nodes, default of all node pools (default: server_type)"
  default     = null
}

variable "image" {
  type        = string
  description = "Image selector (either fcos or rhcos)"
  default     = "fcos"
}

variable "image_release" {
  type        = string
  description = "CoreOS release of the snapshot (label <image>_release), empty for the most recent snapshot. Set by make infrastructure from the installer of OPENSHIFT_RELEASE."
  default     = ""
}
