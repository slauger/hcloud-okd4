# hcloud_images instead of hcloud_image, so a missing snapshot does not break
# terraform destroy. Creating servers without an image fails in the module.
data "hcloud_images" "image" {
  with_selector     = "os=${var.image},image_type=generic"
  with_architecture = [var.architecture]
  with_status       = ["available"]
  most_recent       = true
}

# Snapshot of the CoreOS release that belongs to the OpenShift release
# (snapshot label <image>_release, set by make hcloud_image).
data "hcloud_images" "release" {
  count             = var.image_release != "" ? 1 : 0
  with_selector     = "os=${var.image},image_type=generic,${var.image}_release=${var.image_release}"
  with_architecture = [var.architecture]
  with_status       = ["available"]
  most_recent       = true
}

locals {
  release_image_id = try(data.hcloud_images.release[0].images[0].id, null)
  latest_image_id  = try(data.hcloud_images.image.images[0].id, null)

  # Fall back to the most recent snapshot, e.g. for snapshots built before
  # they were labeled with the release. The nodes update to the OS image of
  # the release on their first boot anyway, it just takes longer.
  image_id = local.release_image_id != null ? local.release_image_id : local.latest_image_id
}

check "image_release" {
  assert {
    condition     = var.image_release == "" || local.release_image_id != null || local.latest_image_id == null
    error_message = "No ${var.image} snapshot for CoreOS release ${var.image_release} found, using the most recent ${var.image} snapshot instead. Run make hcloud_image to build a matching one."
  }
}
