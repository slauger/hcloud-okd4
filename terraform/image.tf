data "hcloud_image" "image" {
  with_selector = "os=fcos,image_type=generic"
  with_status   = ["available"]
  most_recent   = true
}

data "hcloud_image" "bootstrap_image" {
  with_selector = "os=fcos,image_type=bootstrap"
  with_status   = ["available"]
  most_recent   = true
}
