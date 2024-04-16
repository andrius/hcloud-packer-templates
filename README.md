# hcloud-packer-templates

Original repository URL is https://github.com/jktr/hcloud-packer-templates,
it used to build archlinux and nixos images.

I wanted to build my own on-demand development environment in a cloud and
decided to refactor these templates - I use manjaro and manjaro-sway on my laptop.

This repo is used to build linux images (as snapshots) for use with
[Hetzner Cloud](https://www.hetzner.de/cloud) by means of HashiCorp's
[Packer](https://packer.io/).

Templates for the following distros are currently provided:

- manjaro
- ubuntu

I recommend the use of Hetzner's
[hcloud](https://github.com/hetznercloud/cli/tree/master/cli) command
line tool to manage the resulting images. Hetzner also provides a dedicated
[Terraform Provider](https://www.terraform.io/docs/providers/hcloud/index.html)
that you can use to build servers from these images. Please note that
your images cannot yet be (easily) exported from Hetzner's Cloud.

## Building Images using this Repo

Please ensure that you have done the following:

- installed `packer` on your development machine
- set the `HCLOUD_TOKEN` environment variable to your API token
- reviewed/overriden the templates' variables (as necessary)

### Getting Started

To build VM images:

- `$ packer build manjaro.pkr.hcl`

To view info about past builds:

- `$ less packer-manifest.json`

To debug a build:

- `$ packer build -debug -on-error=ask manjaro.pkr.hcl`
- `$ ssh -F/dev/null -i ssh_key_hcloud.pem root@XXX.XXX.XXX.XXX -o StrictHostKeyChecking=no`

### Internals

The resulting images are intended to support a Terraform-based (or
custom) workflow that feels close to the one of native Hetzner VMs.

Hetzner's server infrastructure (mirrors, repos, DNS, NTP, DHCP) and
configuration endpoints are used where possible. This necessarily
involves some analysis of their (partially undocumented) setups and
translations of these to our images, so this may become outdated, may
break, or may not work completely as expected. Error handling is also
pretty bare-bones.

In particular, support for the following features available on
standard Hetzner VMs is desired:

- dynamic hostname
- dynamic root ssh keys
- free-form cloud-init userdata
- full IPv6/IPv4 support
- Hetzner Cloud Networks
- Hetzner Cloud Volumes

The following features are notably unsupported:

- dynamic initial root passwords (please prefer ssh keys)
- automatic server resizing (use rescue mode, or a new server)

A general problem is that much of the data necessary for the features
in the lists above is only allocated after a server is instantiated
from a given image and thus can't be taken into account at image
built-time. Hetzer VMs use an hcloud-specific `cloud-init` provider
for this initialization after their instantiation.

However, the current state of `cloud-init` on Archlinux is less than
ideal, and NixOS has a workflow that's not really compatible. Thus,
these images instead use `hcloud-dl-metadata.service`, which
aggregates and outputs the data normally available to Hetzner VMs to
`/etc/hcloud-metadata.json`, which can then be used in further
distro-specific mechanisms (or directly by you).

Finally, your custom `cloud-init` userdata, which the Hetzner VMs
happen to treat as an execute-on-boot script, is instead handled by
`hcloud-dl-userdata.service`, which only transcribes it into
`/etc/hcloud-userdata` and nothing else.

#### Archlinux and Manjaro

Archlinux images use the file `/etc/hcloud-metadata.json` to drive a
few systemd services, which in turn implement the dynamic features
mentioned above:

- hcloud-hostname.service (sets hostname)
- hcloud-network.service (configures primary and attached networks)
- hcloud-ssh-keys.service (sets ssh root keys)

Any further configuration is up to your provisioning tool.

### Known Issues

- The upstream archlinux bootstrap image's filename is derived from
  its release day. I know of no good way to automatically get this
  date. Set `-var arch-image=archlinux-bootstrap-20XX.XX.XX-x86_64.tar.gz`
  if your builds are failing because of this issue.

- Verifying the archlinux bootstrap image is relatively complex due to
  the trust setup the archlinux team uses. We don't properly derive
  developer key trust from the master key(s), but instead pin the key of
  the developer that usually signs the releases.

## License

You can redistribute and/or modify these files unter the terms of the
GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any
later version. See the LICENSE file for details.
