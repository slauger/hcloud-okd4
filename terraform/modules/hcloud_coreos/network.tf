locals {
  internal_ipv4_addresses = [for s in hcloud_server.server : one(s.network[*].ip)]
}
