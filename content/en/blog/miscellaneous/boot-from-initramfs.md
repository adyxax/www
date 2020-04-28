---
title: "Boot from initramfs shell"
linkTitle: "Boot from initramfs shell"
date: 2014-01-24
description: >
  Boot from initramfs shell
---

I had to finish booting from an initramfs shell, here is how I used `switch_root` to do so :

{{< highlight sh >}}
lvm vgscan
lvm vgchange -ay vg
mount -t ext4 /dev/mapper/vg-root /root
exec switch_root -c /dev/console /root /sbin/init
{{< /highlight >}}
