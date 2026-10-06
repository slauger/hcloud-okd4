terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.27.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.70.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
  }
  required_version = ">= 1.5"
}
