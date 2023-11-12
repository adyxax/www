---
title: Recovering a nixos installation from a Linux rescue image
description: How to chroot into a broken nixos system and fix it
date: 2023-11-13
tags:
- nix
---

## Introduction

This article explains how to chroot into a nixos system from a Linux rescue image. I recently had to do this while installing a nixos at ovh: I used an UEFI base image I prepared for oracle cloud instead of a legacy BIOS image. I could have just started the copy again using the right image, but it was an opportunity for learning and I took it.

## Chrooting into a nixos system

This works from any Linux system given you adjust the device paths. It will mount your nixos and chroot into it:
```sh
mount /dev/sdb2 /mnt/
cd /mnt
mount -R /dev dev
mount -R /proc proc
mount -R /sys sys
mount /dev/sdb1 boot
chroot ./ /nix/var/nix/profiles/system/activate
chroot ./ /run/current-system/sw/bin/bash
```

A nixos system needs to have some runtime things populated under `/run` in order for it to work correctly, that is the reason for the profile activation step.

## Generating a new hardware-configuration.nix

Upon installation, a `/etc/nixos/hardware-configuration.nix` file is automatically created with specifics of your system. If you need to update it, know that its contents comes from the following command:
```sh
nixos-generate-config --show-hardware-config
```

## Building a new configuration

Nixos has a configuration build sandbox that will not work from the chroot. To disable it I had to temporarily set the following in `/etc/nix/nix.conf`:
```sh
sandbox = false
```

Do not forget to reactivate it later!

Next you will need to have a working DNS to make any meaningful change to a nixos configuration, because it will almost certainly need to download some new derivation. Since the `resolv.conf` is a symlink, you need to remove it before writing into it:
```sh
rm /etc/resolv.conf
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
```

You should now be able to rebuild your system to apply your configuration fix:
```sh
nixos-rebuild --install-bootloader boot
```

## Conclusion

Nixos will not break often, and when it does you should be able to simply rollback from your boot loader menu. But if anything worse happens or if you are migrating a nixos installation to another chassis, or salving a hard drive... now you know how to proceed!
