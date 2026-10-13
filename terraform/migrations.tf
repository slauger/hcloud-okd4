# Data volumes of the previous version (one per master/worker, named
# <node>-data, attached by the volume resource itself) are taken over by the
# separate volume and attachment resources, so they keep their data. Once
# renamed to <node>-data1, they no longer match and the imports do nothing.
data "hcloud_volumes" "legacy" {
  with_selector = "cluster=${var.dns_domain}"
}

locals {
  legacy_volume_name = "^((master|worker)[0-9]{2})\\.${replace(var.dns_domain, ".", "\\.")}-data$"

  # Volume keys the current configuration expects for one volume per node
  legacy_targets = merge(
    length(local.master_volumes) > 0 ? { for i in range(var.replicas_master) : format("master%02d", i + 1) => "master" } : {},
    try(length(local.node_pools["worker"].volumes) > 0, false) ? { for i in range(local.node_pools["worker"].count) : format("worker%02d", i + 1) => "worker" } : {}
  )

  legacy_volumes = {
    for v in data.hcloud_volumes.legacy.volumes : "${regex(local.legacy_volume_name, v.name)[0]}-data1" => v
    if can(regex(local.legacy_volume_name, v.name)) && contains(keys(local.legacy_targets), try(regex(local.legacy_volume_name, v.name)[0], ""))
  }
  legacy_master_volumes = { for k, v in local.legacy_volumes : k => v if startswith(k, "master") }
  legacy_worker_volumes = { for k, v in local.legacy_volumes : k => v if startswith(k, "worker") }
}

import {
  for_each = local.legacy_master_volumes
  to       = module.master.hcloud_volume.data[each.key]
  id       = tostring(each.value.id)
}

import {
  for_each = { for k, v in local.legacy_master_volumes : k => v if v.server_id != null }
  to       = module.master.hcloud_volume_attachment.data[each.key]
  id       = tostring(each.value.id)
}

import {
  for_each = local.legacy_worker_volumes
  to       = module.pool["worker"].hcloud_volume.data[each.key]
  id       = tostring(each.value.id)
}

import {
  for_each = { for k, v in local.legacy_worker_volumes : k => v if v.server_id != null }
  to       = module.pool["worker"].hcloud_volume_attachment.data[each.key]
  id       = tostring(each.value.id)
}

# The old addresses are only forgotten, the volumes are imported above.
removed {
  from = module.master.hcloud_volume.volumes

  lifecycle {
    destroy = false
  }
}

removed {
  from = module.pool.hcloud_volume.volumes

  lifecycle {
    destroy = false
  }
}
