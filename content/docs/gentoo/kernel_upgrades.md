---
title: "Gentoo Kernel Upgrades"
description: Gentoo kernel upgrades on adyxax.org
tags:
- gentoo
- linux
---

## Introduction

Now that I am mostly running OpenBSD servers I just use genkernel to build my custom configuration on each node with :
```sh
eselect kernel list
eselect kernel set 1
genkernel all  --kernel-config=/proc/config.gz --menuconfig
nvim --diff /proc/config.gz /usr/src/linux/.config
```

Bellow you will find how I did things previously when centralising the build of all kernels on a collab-jde machine, and distributing them all afterwards. Local nodes would only rebuild local modules and get on with their lives.

## Building on collab-jde

```sh
PREV_VERSION=4.14.78-gentoo
eselect kernel list
eselect kernel set 1
cd /usr/src/linux
for ARCHI in `ls /srv/gentoo-builder/kernels/`; do
    make mrproper
    cp /srv/gentoo-builder/kernels/${ARCHI}/config-${PREV_VERSION} .config
    echo "~~~~~~~~~~ $ARCHI ~~~~~~~~~~"
    make oldconfig
    make -j5
    INSTALL_MOD_PATH=/srv/gentoo-builder/kernels/${ARCHI}/ make modules_install
    INSTALL_PATH=/srv/gentoo-builder/kernels/${ARCHI}/ make install
done
```

## Deploying on each node :

```sh
export VERSION=5.4.28-gentoo-x86_64
wget http://packages.adyxax.org/kernels/x86_64/System.map-${VERSION} -O /boot/System.map-${VERSION}
wget http://packages.adyxax.org/kernels/x86_64/config-${VERSION} -O /boot/config-${VERSION}
wget http://packages.adyxax.org/kernels/x86_64/vmlinuz-${VERSION} -O /boot/vmlinuz-${VERSION}
rsync -a --delete collab-jde.nexen.net:/srv/gentoo-builder/kernels/x86_64/lib/modules/${VERSION} /lib/modules/
eselect kernel set 1
cd /usr/src/linux
cp /boot/config-${VERSION} .config
cp /boot/System.map-${VERSION} System.map
(cd usr ; make gen_init_cpio)
make modules_prepare
emerge @module-rebuild
genkernel --install initramfs --ssh-host-keys=create-from-host
grub-mkconfig -o /boot/grub/grub.cfg
```
