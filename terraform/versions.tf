terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.17.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.60.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
  required_version = ">= 0.14"
}
