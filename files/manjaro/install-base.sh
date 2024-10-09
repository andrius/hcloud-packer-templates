#!/bin/bash

# required env:
# - KEYMAP
# - LOCALE
# - TIMEZONE
#
# optional env
# - EXTRA_PACKAGES

set -euo pipefail

# obtain manjaro boot image and tools
mkdir -p iso
cd iso
tar xzf /tmp/manjaro.tar.gz
cd ..
rm /tmp/manjaro.tar.gz # save ramfs memory

# prepare mounts
readonly iso='/root/iso'
mount --bind "$iso" "$iso" # XXX arch-chroot needs / to be a mountpoint
mount --bind /mnt "$iso/mnt"

# install base
"${iso}/bin/arch-chroot" "$iso" <<EOF
set -euo pipefail

# pacstrap
pacman-key --init
pacman-key --populate archlinux manjaro
pacman-key --refresh-keys
pacman-mirrors -f 5
pacman -Sy
pacstrap /mnt \
  btrfs-progs \
  cloud-guest-utils \
  cloud-init \
  curl \
  docker \
  docker-compose \
  fd \
  fuse2 \
  git \
  gnu-netcat \
  gpgme \
  grub \
  htop \
  inetutils \
  iputils \
  jq \
  keychain \
  linux66 \
  lua \
  manjaro-zsh-config \
  mc \
  micro \
  mosh \
  neovim \
  openssh \
  python \
  python-pip \
  rsync \
  ruby \
  sed \
  syncthing \
  tailscale \
  tig \
  tmux \
  traceroute \
  tree \
  unzip \
  wget \
  which \
  wireguard-tools \
  yay \
  zoxide \
  zsh \
  zsh-autosuggestions \
  zsh-completions \
  zsh-history-substring-search \
  zsh-syntax-highlighting \
  ${EXTRA_PACKAGES}

# fstab
genfstab -U /mnt > /mnt/etc/fstab
echo 'proc /proc proc defaults,hidepid=2 0 0' >> /mnt/etc/fstab
EOF

# configure base
"${iso}/bin/arch-chroot" /mnt <<EOF
set -exuo pipefail

# time
systemctl enable systemd-timesyncd
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# locale
echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
echo '${LOCALE} UTF-8' > /etc/locale.gen
echo 'en_DK.UTF-8 UTF-8' >> /etc/locale.gen
echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen
echo 'lt_LT.UTF-8 UTF-8' >> /etc/locale.gen
echo 'ru_RU.UTF-8 UTF-8' >> /etc/locale.gen
echo 'LANG=${LOCALE}' > /etc/locale.conf
echo 'LC_ALL=en_GB.UTF-8' >> /etc/locale.conf
echo 'LC_COLLATE=en_GB.UTF-8' >> /etc/locale.conf
echo 'LC_MEASUREMENT=en_DK.UTF-8' >> /etc/locale.conf
echo 'LC_NUMERIC=en_DK.UTF-8' >> /etc/locale.conf
echo 'LC_MONETARY=en_LT.UTF-8' >> /etc/locale.conf
locale-gen

# network
mkdir -p /root/.ssh/
systemctl enable \
  cloud-init-local \
  cloud-init \
  cloud-config \
  cloud-final \
  docker \
  sshd \
  systemd-networkd \
  systemd-resolved
  cat > /etc/systemd/network/default.network <<EOF2
  [Match]
  Name=en*
  [Network]
  DHCP=yes
EOF2

# grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg /dev/sda

# hcloud
# these services were uploaded by packer beforehand
for i in /etc/systemd/system/hcloud*.service; do
  systemctl enable "\$i"
done

# cloud-init
echo '' >> /etc/cloud/cloud.cfg
echo '' >> /etc/cloud/cloud.cfg
echo 'users: []' >> /etc/cloud/cloud.cfg
echo 'disable_root: false' >> /etc/cloud/cloud.cfg
echo 'allow_userdata: true' >> /etc/cloud/cloud.etc

# misc
setcap cap_net_admin,cap_net_raw+eip /usr/bin/wg
systemctl set-default multi-user.target
usermod -L root
echo 'manjaro' > /etc/hostname


# https://askubuntu.com/questions/80444/how-to-set-user-passwords-using-passwd-without-a-prompt
# usermod --password 'HASHEDPASSWORD' root

# cleanup
pacman -Scc --noconfirm
EOF

# resolv.conf
# https://wiki.archlinux.org/title/Systemd-resolved#DNS
[ -f /mnt/etc/resolv.conf ] && rm /mnt/etc/resolv.conf
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

# clean up
rm -rf /mnt/root/.bash_history \
	/mnt/var/cache/* \
	/mnt/var/log/pacman.log
