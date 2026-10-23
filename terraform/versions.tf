terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.28.1"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.70.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
  }
  required_version = ">= 1.9"
}
