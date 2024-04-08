packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/hcloud"
    }
  }
}

variable "extra-packages" {
  type    = list(string)
  default = []
}

variable "hcloud-servertype" {
  type    = string
  default = "cx11"
}

variable "hcloud-token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

variable "system-keymap" {
  type    = string
  default = "us"
}

variable "system-locale" {
  type    = string
  default = "en_US.UTF-8"
}

variable "system-timezone" {
  type    = string
  default = "UTC"
}

locals {
  release = "${ legacy_isotime("2006-01") }-01"
  build-id = "${ uuidv4() }"
  build-labels = {
    os-flavor               = "ubuntu"
    "ubuntu/iso.release"   = "${ local.release }"
    "packer.io/build.id"    = "${ local.build-id }"
    "packer.io/build.time"  = "{{ timestamp }}"
    "packer.io/version"     = "{{ packer_version }}"
  }
}

source "hcloud" "ubuntu" {
  server_type  = "${ var.hcloud-servertype }"
  image = "ubuntu-22.04"
  rescue       = "linux64"
  # location     = "hel1"
  location     = "fsn1"
  snapshot_name = "ubuntu-${formatdate("YYYYMMDD-hhmmss", timestamp()) }"
  snapshot_labels = local.build-labels
  ssh_username  = "root"
  token         = "${ var.hcloud-token }"
}

build {
  sources = [ "source.hcloud.ubuntu" ]

  provisioner "shell" {
    script           = "files/filesystem.sh"
    environment_vars = [ "LABEL=${local.build-id}" ]
  }

  provisioner "file" {
    destination = "/mnt/"
    source      = "files/ubuntu/root/"
  }

  provisioner "shell" {
    inline = [
      # "gpg --batch --import /tmp/key-${local.build-id}.gpg",
      "chmod --recursive u=rwX,g=rX,o=rX /mnt",
      "chmod --recursive u=rwx,g=rx,o=rx /mnt/usr/local/bin/*",
    ]
  }

  provisioner "shell" {
    script           = "files/ubuntu/install.sh"
    environment_vars = [
      "UBUNTU_RELEASE=${local.release}",
      "EXTRA_PACKAGES=${join(" ", var.extra-packages)}",
      "KEYMAP=${var.system-keymap}",
      "LOCALE=${var.system-locale}",
      "TIMEZONE=${var.system-timezone}",
    ]
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
