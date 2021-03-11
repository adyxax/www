---
title: "qemu-nbd"
date: 2019-07-01
description: qemu-nbd usage example
tags:
  - linux
  - virtualization
---

## Usage example

{{< highlight sh >}}
modprobe nbd max_part=8
qemu-nbd -c /dev/nbd0 image.img
mount /dev/nbd0p1 /mnt   # or vgscan && vgchange -ay
[...]
umount /mnt
qemu-nbd -d /dev/nbd0
{{< /highlight >}}
