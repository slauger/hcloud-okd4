data "hcloud_image" "image" {
  with_selector = "os=fcos,type=worker"
  with_status   = ["available"]
  most_recent   = true
}

data "hcloud_image" "bootstrap_image" {
  with_selector = "os=fcos,type=bootstrap"
  with_status   = ["available"]
  most_recent   = true
}
