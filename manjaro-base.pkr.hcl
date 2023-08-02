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
  # default = "cx11"
  default = "cx21"
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
  manjaro-release = "${ legacy_isotime("2006-01") }-01"
  build-id = "${ uuidv4() }"
  build-labels = {
    os-flavor               = "manjaro-base"
    "manjaro/iso.release"   = "${ local.manjaro-release }"
    "packer.io/build.id"    = "${ local.build-id }"
    "packer.io/build.time"  = "{{ timestamp }}"
    "packer.io/version"     = "{{ packer_version }}"
  }
}

source "hcloud" "manjaro" {
  server_type  = "${ var.hcloud-servertype }"
  image = "debian-11"
  #image_filter = {
  #  with_selector = [ "os_flavor=debian" ]
  #  most_recent = true
  #}
  rescue       = "linux64"
  # location     = "hel1"
  location     = "fsn1"
  snapshot_name = "manjaro-${formatdate("YYYYMMDD-hhmmss", timestamp()) }"
  snapshot_labels = local.build-labels
  ssh_username  = "root"
  token         = "${ var.hcloud-token }"
}

build {
  sources = [ "source.hcloud.manjaro" ]

  provisioner "shell-local" {
    inline = ["cd ./files/manjaro/sources && [ -f manjaro.tar.gz ] || docker run --platform linux/amd64 --privileged --tty --rm --volume $(pwd):/build -v /proc:/proc manjarolinux/base:latest bash -c 'cd /build && ./create-image.sh'"]
  }

  provisioner "file" {
    destination = "/tmp/manjaro.tar.gz"
    source      = "files/manjaro/sources/manjaro.tar.gz"
    generated   = true
  }

  provisioner "shell" {
    script           = "files/filesystem.sh"
    environment_vars = [ "LABEL=${local.build-id}" ]
  }

  provisioner "file" {
    destination = "/mnt/"
    source      = "files/manjaro/root/"
  }

  provisioner "shell" {
    inline = [
      # "gpg --batch --import /tmp/key-${local.build-id}.gpg",
      "chmod --recursive u=rwX,g=rX,o=rX /mnt",
      "chmod --recursive u=rwx,g=rx,o=rx /mnt/usr/local/bin/*",
    ]
  }

  provisioner "shell" {
    script           = "files/manjaro/install-base.sh"
    environment_vars = [
      "MANJARO_RELEASE=${local.manjaro-release}",
      "EXTRA_PACKAGES=${join(" ", var.extra-packages)}",
      "KEYMAP=${var.system-keymap}",
      "LOCALE=${var.system-locale}",
      "TIMEZONE=${var.system-timezone}",
    ]
  }

  # gem install neovim

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
