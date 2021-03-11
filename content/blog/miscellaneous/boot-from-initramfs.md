---
title: "Boot from initramfs shell"
date: 2014-01-24
description: How to finish booting from an initramfs shell
tags:
  - Debian
---

## The problem

Sometimes, your linux machine can get stuck while booting and drop you into an initramfs shell.

## The solution

All initramfs are potentially different, but almost always feature busybox and common mechanisms. Recently I had to finish booting from an initramfs shell, here is how I used `switch_root` to do so :

{{< highlight sh >}}
lvm vgscan
lvm vgchange -ay vg
mount -t ext4 /dev/mapper/vg-root /root
exec switch_root -c /dev/console /root /sbin/init
{{< /highlight >}}
