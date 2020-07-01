data "hcloud_image" "image" {
  with_selector = "os=${var.image},image_type=generic"
  with_status   = ["available"]
  most_recent   = true
}
