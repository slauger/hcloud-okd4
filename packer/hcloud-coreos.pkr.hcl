variable "os" {
  type        = string
  description = "CoreOS variant, fcos (OKD) or rhcos (OCP)"

  validation {
    condition     = contains(["fcos", "rhcos"], var.os)
    error_message = "The os must be fcos or rhcos."
  }
}

variable "url" {
  type        = string
  description = "URL of the gzip compressed qcow2 image"
}

variable "sha256" {
  type        = string
  description = "SHA256 checksum of the uncompressed qcow2 image"

  validation {
    condition     = can(regex("^[0-9a-f]{64}$", var.sha256))
    error_message = "The sha256 must be a hex encoded SHA256 checksum."
  }
}

variable "stream" {
  type    = string
  default = ""
}

variable "release" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "server_type" {
  type    = string
  default = "cpx32"
}

variable "architecture" {
  type    = string
  default = "x86"

  validation {
    condition     = contains(["x86", "arm"], var.architecture)
    error_message = "The architecture must be x86 or arm."
  }
}

variable "image_type" {
  type    = string
  default = "generic"
}

variable "ignition_config" {
  type    = string
  default = "config-3.0.0.ign"
}

variable "first_boot_kargs" {
  type    = string
  default = "rd.neednet=1 ip=dhcp nameserver=1.1.1.1 nameserver=1.0.0.1"
}

locals {
  qcow2 = "${var.os}-qemu.qcow2"
}

source "hcloud" "coreos" {
  image         = "ubuntu-22.04"
  location      = var.location
  server_type   = var.server_type
  ssh_username  = "root"
  rescue        = "linux64"
  snapshot_name = "${var.os}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  snapshot_labels = {
    os                  = var.os
    image_type          = var.image_type
    architecture        = var.architecture
    "${var.os}_stream"  = var.stream
    "${var.os}_release" = var.release
  }
}

build {
  sources = ["source.hcloud.coreos"]

  provisioner "shell" {
    inline = [
      "set -x",
      "mkdir /source",
      "mount -t tmpfs -o size=4G none /source",
      "cd /source",
      "curl -sfL '${var.url}' | gzip -d > ${local.qcow2}",
      "echo '${var.sha256}  ${local.qcow2}' | sha256sum -c -",
      "qemu-img convert ${local.qcow2} -O raw /dev/sda",
      "partprobe /dev/sda",
      "mkdir /target",
      "udevadm settle",
      "mount \"$(blkid -L boot)\" /target",
      "mkdir /target/ignition",
    ]
  }

  provisioner "file" {
    source      = var.ignition_config
    destination = "/target/ignition/config.ign"
  }

  provisioner "shell" {
    inline = [
      "set -x",
      "cat /target/ignition.firstboot || true",
      "echo \"set ignition_network_kcmdline='${var.first_boot_kargs}'\" > /target/ignition.firstboot",
      "cat /target/ignition.firstboot",
      "cd /",
      "umount /source",
      "umount /target",
    ]
  }
}
