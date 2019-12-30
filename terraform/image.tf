data "hcloud_image" "image" {
  with_selector = "os=fcos"
  with_status   = ["available"]
  most_recent   = true
}
