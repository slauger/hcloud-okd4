# hcloud_images instead of hcloud_image, so a missing snapshot does not break
# terraform destroy. Creating servers without an image fails in the module.
data "hcloud_images" "image" {
  with_selector     = "os=${var.image},image_type=generic"
  with_architecture = [var.architecture]
  with_status       = ["available"]
  most_recent       = true
}

locals {
  image_id = try(data.hcloud_images.image.images[0].id, null)
}
