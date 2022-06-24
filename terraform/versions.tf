terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "2.27.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.33.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "1.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "2.3.1"
    }
  }
  required_version = ">= 0.14"
}
