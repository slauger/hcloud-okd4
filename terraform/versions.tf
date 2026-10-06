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
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
  required_version = ">= 0.14"
}
