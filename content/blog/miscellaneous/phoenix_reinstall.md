---
title: Reinstalling my backup server
description: How to install Alpine Linux with a custom raid1 partitioning
date: 2022-03-28
tags:
  - Alpine
---

## Introduction

Last week I reinstalled my backup server. It was successfully running OpenBSD for a few years but I decided I wanted to run containers on it again for some experiments, so back to Linux.

I hesitated with Gentoo but decided to give a fair shot to Alpine Linux instead. I have used it extensively on virtual machines but not so much on bare metal so here I go. In particular the documentation on how to perform a custom partitioning was a bit lacking so hopefully this blog post will fill in some gaps.

## Booting the installer

Booting the installer is straightforward : download the latest image from https://alpinelinux.org/downloads/ and copy it to a usb drive (`/dev/sdb` in the example bellow). I chose the extended version of the installer because I will need to install additional tools to setup the disks just right :
```sh
wget https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-extended-3.15.3-x86_64.iso
dd if=alpine-extended-3.15.3-x86_64.iso of=/dev/sdb bs=1M
sync
```

## Making the installer reachable through ssh

This step is optional but I like being able to simply paste commands from this website during the installation process. The following will start ssh and setup static networking (the ips are to be customized to your network of course) :
```sh
apk add openssh
echo 'PermitRootLogin yes' > /etc/ssh/sshd_config
/etc/init.d/sshd start
ip a a 192.168.1.3/24 dev eth0
ip l set up dev eth0
ip r a default via 192.168.1.1
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
passwd
```

## RAID1 partitioning

First we install a few tools:
```sh
echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/main' > /etc/apk/repositories
apk add sgdisk mdadm xfsprogs grub efibootmgr dosfstools partx
```

For RAID1 I need two identical disks. Since in my case its two SSD drives, I use blkdiscard to clean them.

I planed for 3 partitions:
- a 512M /boot that will be your UEFI partition
- a 16G /
- the remainder of the disks for an encrypted /data
```sh
for DEVICE in `echo sda sdb`; do
	DISK=/dev/$DEVICE
	blkdiscard $DISK
	sgdisk -n1:0:+512M -t1:FD00 $DISK
	sgdisk -n2:0:+16G -t2:FD00 $DISK
	sgdisk -n3:0:0 -t3:FD00 $DISK
	partx -a $DISK
done
```

If `partx` fails with a error and cannot reread the new partitions you will have to reboot. Sadly, it can happen with some consumer grade motherboards.

The UEFI partition needs a raid metadata version 1.0 in order to have the metadata at the end of the partition. This will ensure the UEFI (which is not raid aware) can boot from a single disk:
```sh
mdadm --create --run --level=1 --raid-devices=2 --metadata=1.0 /dev/md1 /dev/sda1 /dev/sdb1
mdadm --create --run --level=1 --raid-devices=2 /dev/md2 /dev/sda2 /dev/sdb2
mdadm --create --run --level=1 --raid-devices=2 /dev/md3 /dev/sda3 /dev/sdb3
blkdiscard /dev/md1
blkdiscard /dev/md2
blkdiscard /dev/md3
```

I like xfs so that is what I will use for `/` (`/data` will come later):
```sh
mkfs.fat -F 32 -n efi-boot /dev/md1
mkfs.xfs /dev/md2
mount -t xfs /dev/md2 /mnt
mkdir -p /mnt/boot
mount -t vfat /dev/md1 /mnt/boot
```

## Running the installer

You can run the installer normally, just beware at the end when choosing disks : you will not be able to install to `/dev/md2` so the installer will stop but still record all your answers.
```sh
setup-alpine
```

You just need to trigger the next step manually with:
```sh
setup-disk /mnt
```

## Post installation steps

We need to customise some things before your system can boot. In order to do that we will need to chroot into your new system:
```sh
mount -t proc none /mnt/proc
mount -t sysfs  none /mnt/sys
mount -o bind /dev /mnt/dev
chroot /mnt
```

First we want to preserve the mdadm numbering we need with the following:
```sh
mdadm --detail --scan >> /etc/mdadm.conf
mkinitfs -c /etc/mkinitfs/mkinitfs.conf -b /
echo "/dev/md2        /       xfs     rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota 0 1
/dev/md1        /boot   vfat    rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=utf8,shortname=mixed,errors=remount-ro 0 2
" > /etc/fstab
```

Next the installer botched the UEFI part, here is how to fix it:
```sh
rm -rf /boot/efi/EFI
grub-install /dev/md2 --efi-directory=/boot
efibootmgr -c -g -d /dev/sda -p 1 -w -L grub_sda -l EFI/grub/grubx64.efi
efibootmgr -c -g -d /dev/sdb -p 1 -w -L grub_sdb -l EFI/grub/grubx64.efi
```

You can now exit your chroot then reboot:
```sh
exit
reboot
```

Don't forget to unplug the installation media!

## Post install

Here is how I setup my encrypted `/data`:
```sh
apk add cryptsetup
cryptsetup luksFormat --cipher aes-xts-plain64 /dev/md3
cryptsetup luksOpen --allow-discards /dev/md3 data
mkdir /data
echo "/dev/mapper/data /data xfs noauto,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota 0 0" >> /etc/fstab
mount /data
```
