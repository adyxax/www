---
title: Install FreeBSD from linux
description: How to install FreeBSD at hosting providers that do not support it
tags:
- FreeBSD
- UpdateNeeded
---

## Introduction

This article explains a simple method to install FreeBSD when all you have is a linux and a remote console.

## Option 1: from an official pre-built vm image

First login as root on the linux you want to reinstall as Freebsd. Identify the disk device you want to install on, update the url below to the latest release you want and run :
```sh
wget https://download.freebsd.org/ftp/releases/VM-IMAGES/13.1-RELEASE/amd64/Latest/FreeBSD-13.1-RELEASE-amd64.raw.xz \
     -O - | xz -dc | dd of=/dev/vda bs=1M conv=fdatasync
```

When all is done, force a reboot of your machine and connect to the remote console. Your FreeBSD system should boot and leave you with an authentication prompt. Just type in root (it will not ask for a password) and go through this post installation checklist :
- run `freebsd-update fetch install` then reboot
- set a root password with `passwd`
- add a user account with `adduser`, put it in the `wheel` group
- add a ssh authorized_keys for your new user
- change your hostname in `/etc/rc.conf`
- activate openssh with `service sshd enable && service sshd start`
- if dhcp is not sufficient configure your network with `ifconfig`, `pkill dhclient` if necessary and check the default route(s)
- don't forget to configure ipv6 too
- configure your `resolv.conf`
- install python3 for your first ansible run

## Option 2: from a custom vm image

This method is necessary if you need control over the partitioning, like root on zfs.

Execute a standard installation from a virtual machine on your workstation or another server, I use [qemu]({{< ref "qemu-bis.md" >}}) for that. With you have your image ready, boot the linux server you want to convert to freebsd and run something like:
```sh
ssh myth.adyxax.org "dd if=freebsd.raw" | dd of=/dev/sda
```
The goal of this command is to connect a server hosting your image and `dd` it to the hard drive the server you want to convert. Don't forget to `sync` your disks!

Upon rebooting, you should have your freebsd running. Resize your drive with something like:
```sh
gpart show
gpart recover da0
gpart resize -i 3 da0
zpool online -e zroot da0p3
```
