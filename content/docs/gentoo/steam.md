---
title: "Steam"
description: How to make steam work seamlessly on gentoo with a chroot
---

## Introduction

I am not using a multilib profile on gentoo (I use amd64 only everywhere), so when the time came to install steam I had to get a little creative. Overall I believe this is the perfect
way to install and use steam as it self contains it cleanly while not limiting the functionalities. In particular sound works, as does the hardware acceleration in games. I tried to
achieve that with containers but didn't quite made it work as well as this chroot setup.

## Installation notes

Note that there is no way to provide a "most recent stage 3" installation link. You will have to browse http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/
and adjust the download url manually bellow :

{{< highlight sh >}}
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
emerge dev-vcs/git -q
wget -P /etc/portage/repos.conf/ https://raw.githubusercontent.com/anyc/steam-overlay/master/steam-overlay.conf
emaint sync --repo steam-overlay
emerge --ask games-util/steam-launcher
useradd -m -G audio,video steam
{{< /highlight >}}

## Launch script

Note that we use `su` and not `su -` since we need to preserve the environment. If you don't you won't get any sound in game. The pulseaudio socket is shared through the mount of
/run inside the chroot :
{{< highlight sh >}}
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
{{< /highlight >}}
