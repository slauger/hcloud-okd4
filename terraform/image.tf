data "hcloud_image" "image" {
  with_selector = "os=fcos,image_type=generic"
  with_status   = ["available"]
  most_recent   = true
}
