terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.27.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.44.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
  required_version = ">= 0.14"
}
