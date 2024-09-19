---
title: 'Fixing an encrypted Debian system boot'
description: 'From booting in UEFI mode to legacy BIOS mode'
date: '2024-09-19'
tags:
- Debian
---

## Introduction

Some time ago, I reinstalled one of my OVH vps instances. I used a virtual machine image of a Debian Linux that I initially prepared for a GCP host a few months ago. It was setup to boot with UEFI, and I discovered that OVH does not offer it (at least on its small VPS offering).

It is a problem because this is a system with an encrypted root partition. In order to boot with an encrypted partition in BIOS mode, grub needs some extra space than it does not when in UEFI mode.

I could rebuild an image from scratch, or I could hop onto an OVH rescue image and fix it. I took the later approach in order to refresh my rescue skills.

## Mounting the partitions from the rescue image

This system has an encrypted block device holding an LVM set of volumes. Since the rescue image does not have the necessary tools, I installed them with:
``` shell
apt update -qq
apt install -y cryptsetup lvm2
```

I refreshed my knowledge of the layout with
``` shell
blkid
fdisk -l /dev/sdb
```

Opening the encrypted block device is done with:
``` shell
cryptsetup luksOpen /dev/sdb3 sda3_crypt
```

Note that I am mounting a sdb device because we are in OVH rescue, but it was known as sda during the installation. I need to use the same name otherwise grub will mess up when I regenerate its configuration and the system will not reboot properly.

The LVM subsystem now needs to be activated with:
``` shell
vgchange -ay vg
```

Now to mount the partitions and chroot into our system:

``` shell
mount /dev/vg/root /mnt
cd /mnt
mount -R /dev dev
mount -R /proc proc
mount -R /sys sys
chroot ./
mount /boot
```

## Replacing the EFI partition with a BIOS boot partition

My system had an EFI partition in /dev/sdb1: this is not suitable for booting a grub2 system to an encrypted volume directly from BIOS. I replaced it with a BIOS boot partition with:
``` shell
fdisk /dev/sdb
Command (m for help): d
Partition number (1-3, default 3): 1
Partition 1 has been deleted.

Command (m for help): n
Partition number (1,4-128, default 1): 1
First sector (34-41943006, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-1050623, default 1050623):

Created a new partition 1 of type 'Linux filesystem' and of size 512 MiB.

Command (m for help): t
Partition number (1-3, default 3): 1
Partition type or alias (type L to list all): 4
w
```

Reinstalling grub was a matter of:
``` shell
apt install grub-pc
update-grub
grub-install /dev/sdb
```

I am not sure whether it was necessary or not but I rebuilt the initramfs in case the set of modules needed by the kernel would be different:
``` shell
update-initramfs -u
```

## Cleanup

Close the chroot session with either `C-d` or the `exit` command. Then umount all partitions with:
``` shell
cd /
umount -R -l /mnt
```

Deactivate the LVM subsystem with:
``` shell
vgchange -an
```

Close the luks volume with:
``` shell
cryptsetup luksClose sda3_crypt
```

Sync all data to disks just in case:
``` shell
sync
```

Then reboot in normal mode from the OVH management webui.

## Conclusion

This was a fun repair operation!
