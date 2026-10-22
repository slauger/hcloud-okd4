# Separate file, so the toolbox image installs the plugin with packer init
# without depending on the template.
packer {
  required_plugins {
    hcloud = {
      # renovate: datasource=github-releases depName=hashicorp/packer-plugin-hcloud
      version = "1.8.2"
      source  = "github.com/hashicorp/hcloud"
    }
  }
}
