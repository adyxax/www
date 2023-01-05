---
title: Recover a FreeBSD system using a liveUSB
description: How to attach your geli encrypted devices, mount zfs and chroot
date: 2023-01-05
tags:
- FreeBSD
- toolbox
---

## Introduction

I reinstalled my backup server to FreeBSD after a few months [on Alpine Linux]({{< ref "phoenix_reinstall.md" >}}). I was happy with Alpine running on bare metal, but since I no longer needed to run Linux containers on this machine I wanted to come back to BSD for the simplicity and consistency of this system. I used the automated installation with an encrypted zfs mirror of two drives.

When I ran my ansible automation for the first time on this fresh installation, I did not notice it messed up my `/boot/loader.conf` and removed two vital lines for this system:
```
aesni_load="YES"
geom_eli_load="YES"
```

Of course the server could not boot without those, here is how to solve this issue if it happens to you.

## Booting from a LiveUSB

If you do not already have one, download a LiveUSB image from https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/13.1/FreeBSD-13.1-RELEASE-amd64-memstick.img and copy it to your USB flash drive with a command like:
```sh
dd if=/home/julien/Downloads/FreeBSD-13.1-RELEASE-amd64-memstick.img of=/dev/sdb bs=1M
```

Insert it into your computer then select the proper temporary boot device using the proper key during the bios loading process (F11 for this motherboard of mine). When you reach the installer screen, select the option to `Start a Shell`.

## Unlocking your geli encrypted devices

These commands are not complicated, but here they are for posterity:
```sh
geli attach /dev/ada0p4
geli attach /dev/ada1p4
```

If you are unsure about your disks numbering, `geom disk list` is your friend.

## Mount your zfs filesystems

```sh
zpool import -fR /mnt zroot
mount -t zfs zroot/ROOT/default /mnt
zfs mount -a
```

## Chroot into your system

Contrary to Linux for which the chroot process requires a little preparation, FreeBSD is a breeze:
```sh
chroot /mnt
```

and voila! If you need access to more things and require the comfort of your desktop computer or laptop:
```sh
mount -t devfs none /dev
ifconfig re0 inet 192.168.1.2/24
route add default 192.168.1.1
service sshd start
```

You can now enjoy your system as if it booted normally and fix whatever you need to fix.
