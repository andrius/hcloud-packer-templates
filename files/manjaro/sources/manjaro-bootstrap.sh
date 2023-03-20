#!/usr/bin/env bash

set -xueo pipefail

pacman -Sy --quiet --noprogressbar --noconfirm arch-install-scripts

PACMAN_DB="$(mktemp -d)"
TMPDIR="$(mktemp -d)"
pacman -Syuw --quiet --noprogressbar --noconfirm --dbpath ${PACMAN_DB} $(cat packages | xargs)
cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* "${TMPDIR}"/
pushd "${TMPDIR}"
find /var/cache/pacman/pkg/ -type f -not -iname '*.sig' -exec tar -xf {} \;
mkdir -p proc sys dev run tmp
ln -s usr/bin bin
popd
mount --bind ${TMPDIR} ${TMPDIR}
arch-chroot "${TMPDIR}" locale-gen
arch-chroot "${TMPDIR}" pacman-mirrors -f 5
arch-chroot "${TMPDIR}" pacman -Sy
arch-chroot "${TMPDIR}" pacman-key --init
arch-chroot "${TMPDIR}" pacman-key --populate archlinux manjaro
tar --numeric-owner --xattrs --acls --exclude-from=exclude -C "${TMPDIR}" -cz . -f manjaro-bootstrap.tar.gz
umount "${TMPDIR}"
rm -rf "${TMPDIR}"
