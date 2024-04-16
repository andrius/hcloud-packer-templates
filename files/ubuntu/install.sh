#!/bin/bash

# This script is running in the context of the Hetzner rescue system.
# It does dowlnoad the latest Ubuntu netboot image and installs the base system.
# See also:
# - https://discourse.ubuntu.com/t/netbooting-the-live-server-installer/14510
# - https://www.releases.ubuntu.com/mantic/

# required env:
# - KEYMAP
# - LOCALE
# - TIMEZONE
#
# optional env
# - EXTRA_PACKAGES

set -xuo pipefail

###############################################################################
# Prepare the apt sources
apt -y update
apt install -yqq wget gpg apt-transport-https

add-apt-repository -y ppa:nextcloud-devs/client

# https://www.omgubuntu.co.uk/2022/04/how-to-install-firefox-deb-apt-ubuntu-22-04
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); print "\n"$0"\n"}'
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee -a /etc/apt/sources.list.d/mozilla.list
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | tee /etc/apt/preferences.d/mozilla

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

wget -qO- https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

apt -y update

###############################################################################
# Install the base system
apt install -yqq \
	ansible \
	ansible-lint \
	asciinema \
	autossh \
	base-files \
	bat \
	btrfs-progs \
	build-essential \
	ca-certificates \
	cairo-dock \
	checkinstall \
	cloud-guest-utils \
	cloud-init \
	cmake \
	cmake-data \
	code \
	curl \
	dbus-x11 \
	dialog \
	dmz-cursor-theme \
	duf \
	entr \
	eslint \
	expect \
	feh \
	file \
	firefox \
	firefox xorg \
	fuse2fs \
	fzf \
	gettext \
	gist \
	git \
	git-crypt \
	git-flow \
	gnome-keyring \
	gnupg2 \
	google-chrome-stable \
	gopls \
	hsetroot \
	htop \
	httpie \
	hub \
	i3 \
	i3-wm \
	i3lock \
	imagemagick \
	jq \
	jsonlint \
	keepassxc \
	keyboard-configuration \
	keychain \
	kitty \
	libasound2-dev \
	libcairo2-dev \
	libcurl4-openssl-dev \
	libexo-2-0 \
	libfuse2 \
	libgtk2.0-0 \
	libjsoncpp-dev \
	libluajit-5.1-2 \
	libluajit-5.1-common \
	libmpdclient-dev \
	libmsgpackc2 \
	libncurses-dev \
	libnl-genl-3-dev \
	libpulse-dev \
	libpulse-dev i3-wm \
	libtermkey1 \
	libtree-sitter0 \
	libunibilium4 \
	libuv1-dev \
	libvterm0 \
	libwebkit2gtk-4.0-37 \
	libxcb-composite0-dev \
	libxcb-cursor-dev \
	libxcb-ewmh-dev \
	libxcb-icccm4-dev \
	libxcb-image0-dev \
	libxcb-randr0-dev \
	libxcb-util0-dev \
	libxcb-xkb-dev \
	libxcb-xrm-dev \
	libxcb1-dev \
	lua-luv \
	lua5.4 \
	luarocks \
	lxappearance \
	maim \
	mc \
	meld \
	micro \
	mosh \
	most \
	mtr-tiny \
	mypy \
	nano \
	ncal \
	ncurses-bin \
	ncurses-term \
	neofetch \
	net-tools \
	nextcloud-desktop \
	ngrep \
	ninja-build \
	ninja-build gettext \
	nmap \
	nnn \
	nodejs \
	npm \
	optipng \
	papirus-icon-theme \
	pcmanfm \
	pinentry-gnome3 \
	pkg-config \
	pngquant \
	polybar \
	prettyping \
	proxychains4 \
	python3 \
	python3-flake8 \
	python3-greenlet \
	python3-msgpack \
	python3-pip \
	python3-pycodestyle \
	python3-pyflakes \
	python3-pynvim \
	python3-sphinx \
	python3-venv \
	python3-xcbgen \
	qrencode \
	rbenv \
	remmina \
	remmina-plugin-vnc \
	ripgrep \
	rofi \
	rsync \
	rtorrent \
	ruby \
	shellcheck \
	shfmt \
	shotwell \
	sngrep \
	speedtest-cli \
	sshfs \
	sshpass \
	sshuttle \
	sudo \
	tig \
	tigervnc-common \
	tigervnc-standalone-server \
	tldr \
	tmate \
	tmux \
	traceroute \
	tree \
	unison \
	universal-ctags \
	unzip \
	util-linux \
	w3m \
	wget \
	wireguard-tools \
	xcb-proto \
	xclip \
	xdotool \
	xorg \
	xrdp \
	yamllint \
	yank \
	zip \
	zoxide \
	zsh \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	xserver-xorg-core \
	;
:

###############################################################################
# Install Docker
curl -sSL https://get.docker.com/ | sh

###############################################################################
# Install eget and some cli tools
curl https://zyedidia.github.io/eget.sh | sh
chmod +x eget
mkdir -p /usr/local/bin
mv eget /usr/local/bin/
mkdir -p /tmp/eget-packages
cd /tmp/eget-packages
eget --file=hcloud hetznercloud/cli && chmod +x hcloud && sudo mv hcloud /usr/local/bin/
eget nektos/act
eget jesseduffield/lazygit
eget rhysd/actionlint
eget scaleway/scaleway-cli
eget zellij-org/zellij
eget yt-dlp/yt-dlp
chmod +x *
mv * /usr/local/bin/
ln -s /usr/local/bin/yt-dlp /usr/local/bin/youtube-dl
cd -
rm -rf /tmp/eget-packages

###############################################################################
# Install NeoVim
mkdir -p /tmp/neovim
cd /tmp/neovim

git clone https://github.com/neovim/neovim.git .
# git checkout v0.9.5

make CMAKE_BUILD_TYPE=Release all
sudo checkinstall -y --nodoc --install=no --pkgname=neovim --strip=yes --deldoc=yes --deldesc=yes --delspec=yes

DEB_PACKAGE="$(find . -type f -iname '*.deb')"

dpkg -i ${DEB_PACKAGE}
cd -
rm -rf neovim

###############################################################################
# Install Polybar
mkdir -p /tmp/polybar
cd /tmp/polybar

git clone https://github.com/polybar/polybar .
git checkout 3.7.1
git submodule update --init --recursive

# Set the CXX compiler to a version compatible with available packages
export CXX=g++

# Build and install Polybar
mkdir build
cd build
# cmake -DENABLE_ALSA=ON -DENABLE_PULSEAUDIO=ON -DENABLE_I3=ON ..
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_ALSA=ON -DENABLE_PULSEAUDIO=ON -DENABLE_I3=ON ..
make -j$(nproc)
sudo checkinstall -y --nodoc --install=no --pkgname=polybar --strip=yes --deldoc=yes --deldesc=yes --delspec=yes

DEB_PACKAGE="$(find . -type f -iname '*.deb')"
dpkg -i ${DEB_PACKAGE}
cd -
rm -rf polybar

###############################################################################
# System upgrade and cleanup
apt -yqq dist-upgrade
apt -y clean all
apt -y autoremove
