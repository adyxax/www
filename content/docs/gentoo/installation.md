---
title: "Installation"
description: Installation of a gentoo system
tags:
- gentoo
- linux
- UpdateNeeded
---

## Introduction

When installing a gentoo system for the first time, please refer to the wonderfull [gentoo handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64). This page is just installation notes shorthand when you know exactly what you are doing.

## Installation media

You can get a bootable iso or liveusb from https://www.gentoo.org/downloads/. I recommend the minimal one. To create a bootable usb drive juste use `dd` to copy the image on it. Then boot on this brand new installation media.

Once you boot on the installation media, you can start sshd and set a temporary password and proceed with the installation more confortably from another machine :

```sh
/etc/init.d/sshd start
passwd
```

Don't forget to either run `dhcpcd` or manually set an ip and gateway to the machine.

## Partitionning

There are several options depending on wether you need soft raid, full disk encryption or a simple root device with no additional complications. It will also differ if you are using a virtual machine or a physical one.

```sh
tmux
blkdiscard /dev/nvme0n1
sgdisk -n1:0:+2M -t1:EF02 /dev/nvme0n1
sgdisk -n2:0:+512M -t2:EF00 /dev/nvme0n1
sgdisk -n3:0:0 -t3:8300 /dev/nvme0n1
mkfs.fat -F 32 -n efi-boot /dev/nvme0n1p2
mkfs.xfs /dev/nvme0n1p3
mount /dev/sda3 /mnt/gentoo
cd /mnt/gentoo
```

Make sure you do not repeat the mistake I too often make by mounting something to /mnt while using the liveusb/livecd. You will lose your shell if you do this and will need to reboot!

## Get the stage3 and chroot into it

Get the stage 3 installation file from https://www.gentoo.org/downloads/. I personnaly use the non-multilib one from the advanced choices, since I am no longer using and 32bits software except steam, and I use steam from a multilib chroot.

Put the archive on the server in /mnt/gentoo (you can simply wget it from there), then extract it :
```sh
tar xpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
mount /dev/nvme0n1p2 boot
mount -R /proc proc
mount -R /sys sys
mount -R /dev dev
chroot .
```

## Initial configuration

We prepare the local language of the system :
```sh
echo 'LANG="en_US.utf8"' > /etc/env.d/02locale
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
env-update && source /etc/profile
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
```

We set a loop device to hold the portage tree. It will be formatted with optimisation for the many small files that compose it :
```sh
mkdir -p /srv/gentoo-distfiles
truncate -s 10G /portage.img
mke2fs  -b 1024 -i 2048 -m 0 -O "dir_index" -F /portage.img
tune2fs -c 0 -i 0 /portage.img
mkdir /usr/portage
mount -o loop,noatime,nodev /portage.img /usr/portage/
```

We set default compilation options and flags. If you are not me and cannot rsync this location, you can browse it from https://packages.adyxax.org/x86-64/etc/portage/ :
```sh
rsync -a --delete packages.adyxax.org:/srv/gentoo-builder/x86-64/etc/portage/ /etc/portage/
sed -i /etc/portage/make.conf -e s/buildpkg/getbinpkg/
echo 'PORTAGE_BINHOST="https://packages.adyxax.org/x86-64/packages/"' >> /etc/portage/make.conf
```

We get the portage tree and sync the timezone
```sh
emerge --sync
```

## Set hostname and timezone

```sh
export HOSTNAME=XXXXX
sed -i /etc/conf.d/hostname -e /hostname=/s/=.*/=\"${HOSTNAME}\"/
echo "Europe/Paris" > /etc/timezone
emerge --config sys-libs/timezone-data
```

## Check cpu flags and compatibility

TODO
```sh
emerge cpuid2cpuflags -1q
cpuid2cpuflags
gcc -### -march=native /usr/include/stdlib.h
```

## Rebuild the system

```sh
emerge --quiet -e @world
emerge --quiet dosfstools app-admin/logrotate app-admin/syslog-ng app-portage/gentoolkit \
       dev-vcs/git bird openvpn htop net-analyzer/tcpdump net-misc/bridge-utils \
       sys-apps/i2c-tools sys-apps/pciutils sys-apps/usbutils sys-boot/grub sys-fs/ncdu \
       sys-process/lsof net-vpn/wireguard-tools
emerge --unmerge nano -q
```

## Grab a working kernel

Next we need to Grab a working kernel from our build server along with its modules. If you don't have one already, you have some work to do!

Check the necessary hardware support with :
```sh
i2cdetect -l
lspci -nnk
lsusb
```

TODO specific page with details on how to build required modules like the nas for example.
```sh
emerge gentoo-sources genkernel -q
...
```

## Final configuration steps

### fstab

```sh
# /etc/fstab: static file system information.
#
#<fs>         <mountpoint>  <type>  <opts>              <dump/pass>
/dev/vda3     /             ext4    noatime,discard     0  1
/dev/vda2     /boot         vfat    noatime             1  2
/portage.img  /usr/portage  ext2    noatime,nodev,loop  0  0
```

### networking
```sh
echo 'hostname="phoenix"' > /etc/conf.d/hostname
echo 'dns_domain_lo="adyxax.org"
config_eth0="192.168.1.3 netmask 255.255.255.0"
routes_eth0="default via 192.168.1.1"' > /etc/conf.d/net
cd /etc/init.d
ln -s net.lo net.eth0
rc-update add net.eth0 boot
```

### Grub

TODO especially the conf in /etc/default/grub when using an encrypted /

In the case of UEFI use something like :
```sh
grub-install --efi-directory=/boot/ /dev/nvme1n1
grub-mkconfig -o /boot/grub/grub.cfg
```

### /etc/hosts

```sh
scp root@collab-jde.nexen.net:/etc/hosts /etc/
```

### root account access

```sh
mkdir -p /root/.ssh
echo ' ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco  hurricane' > /root/.ssh/authorized_keys
passwd
```

### Add necessary daemons on boot
```sh
rc-update add syslog-ng default
rc-update add cronie default
rc-update add sshd default
```

## TODO

```sh
net-firewall/shorewall
...
rc-update add shorewall default
sed '/PRODUCTS/s/=.*/="shorewall"/' -i /etc/conf.d/shorewall-init
rc-update add shorewall-init boot

net-analyzer/fail2ban
echo '[sshd]
enabled  = true
filter = sshd
ignoreip = 127.0.0.1/8  10.1.0.0/24  37.187.103.36  137.74.173.247  90.85.207.113
bantime  = 3600
banaction = shorewall
logpath = /var/log/messages
maxretry = 3' > /etc/fail2ban/jail.d/sshd.conf
rc-update add fail2ban default

app-emulation/docker
/etc/docker/daemon.json
{ "iptables": false }
rc-update add docker default

app-emulation/lxd
rc-update add lxd default
```

## References

- http://blog.siphos.be/2013/04/gentoo-protip-using-buildpkgonly/
- https://wiki.gentoo.org/wiki/Genkernel
- https://wiki.gentoo.org/wiki/Kernel/Configuration
- https://wiki.gentoo.org/wiki/Kernel
- https://forums.gentoo.org/viewtopic-t-1076024-start-0.html
- https://wiki.gentoo.org/wiki/Binary_package_guide#Setting_up_a_binary_package_host
