#!/usr/bin/env bash

set -xueo pipefail

pacman -Sy --quiet --noprogressbar --noconfirm make arch-install-scripts manjaro-tools docker

TMPDIR="$(mktemp -d)"

env -i pacstrap -C /usr/share/manjaro-tools/pacman-default.conf -c -G -M "${TMPDIR}" $(cat packages | xargs)
set +e
cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* "${TMPDIR}"/
set -e
mount --bind ${TMPDIR} ${TMPDIR}

arch-chroot "${TMPDIR}" locale-gen
arch-chroot "${TMPDIR}" pacman-key --init
arch-chroot "${TMPDIR}" pacman-key --populate archlinux manjaro
arch-chroot "${TMPDIR}" pacman-mirrors -f 5

[ -f manjaro.tar.gz ] && rm  manjaro.tar.gz

tar --numeric-owner --xattrs --acls --exclude-from=exclude -C "${TMPDIR}" -cz . -f manjaro.tar.gz

umount "${TMPDIR}"
rm -rf "${TMPDIR}"
