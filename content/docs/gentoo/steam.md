---
title: "Steam"
description: How to make steam work seamlessly on gentoo with a chroot
tags:
- gentoo
- linux
---

## Introduction

I am not using a multilib profile on gentoo (I use amd64 only everywhere), so when the time came to install steam I had to get a little creative. Overall I believe this is the perfect
way to install and use steam as it self contains it cleanly while not limiting the functionalities. In particular sound works, as does the hardware acceleration in games. I tried to
achieve that with containers but didn't quite made it work as well as this chroot setup.

## Installation notes

Note that there is no way to provide a "most recent stage 3" installation link. You will have to browse http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/
and adjust the download url manually bellow :

```sh
mkdir /usr/local/steam
cd /usr/local/steam
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-20190122T214501Z.tar.xz
tar -xvpf stage3*
rm stage3*
cp -L /etc/resolv.conf etc/
cp -L /etc/locale.gen etc/
mkdir usr/portage
mkdir -p srv/gentoo-distfiles
mount -R /dev dev
mount -R /sys sys
mount -t proc proc proc
mount -R /usr/portage usr/portage
mount -R /usr/src usr/src
mount -R /srv/gentoo-distfiles/ srv/gentoo-distfiles/
mount -R /run run
cp /etc/portage/make.conf etc/portage/
sed -e '/LLVM_TARGETS/d' -e '/getbinpkg/d' -i etc/portage/make.conf
chroot .
locale-gen
env-update && source /etc/profile
eselect profile set default/linux/amd64/17.1
mkdir /etc/portage/package.accept_keywords
echo "games-util/steam-launcher  ~amd64
games-util/game-device-udev-rules  ~amd64" > /etc/portage/package.accept_keywords/steam
mkdir /etc/portage/package.use
echo "x11-libs/libX11 abi_x86_32
x11-libs/libXau abi_x86_32
x11-libs/libxcb abi_x86_32
x11-libs/libXdmcp abi_x86_32
x11-base/xcb-proto abi_x86_32
virtual/opengl abi_x86_32
x11-libs/cairo X
media-libs/libglvnd X
media-libs/mesa  abi_x86_32
dev-libs/expat abi_x86_32
media-libs/libglvnd abi_x86_32
sys-libs/zlib abi_x86_32
x11-libs/libdrm abi_x86_32
x11-libs/libxshmfence abi_x86_32
x11-libs/libXext abi_x86_32
x11-libs/libXxf86vm abi_x86_32
x11-libs/libXfixes abi_x86_32
app-arch/zstd abi_x86_32
sys-devel/llvm abi_x86_32
x11-libs/libXrandr abi_x86_32
x11-libs/libXrender abi_x86_32
dev-libs/libffi abi_x86_32
sys-libs/ncurses abi_x86_32
x11-libs/libpciaccess abi_x86_32" > /etc/portage/package.use/steam
emerge world -uDNq
emerge dev-vcs/git media-sound/pavucontrol media-libs/openal x11-base/xorg-drivers x11-terms/xterm -q
wget -P /etc/portage/repos.conf/ https://raw.githubusercontent.com/anyc/steam-overlay/master/steam-overlay.conf
emaint sync --repo steam-overlay
emerge games-util/steam-launcher -q
useradd -m -G audio,video steam
```

## Launch script

Note that we use `su` and not `su -` since we need to preserve the environment. If you don't you won't get any sound in game. The pulseaudio socket is shared through the mount of
/run inside the chroot :
```sh
su
cd /usr/local/steam
mount -R /dev dev
mount -R /sys sys
mount -t proc proc proc
mount -R /usr/portage usr/portage
mount -R /usr/src usr/src
mount -R /run run
chroot .
env-update && source /etc/profile
su steam
steam
```
