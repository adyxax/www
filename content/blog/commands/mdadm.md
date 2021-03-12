---
title: "mdadm"
date: 2011-11-15
description: some mdadm command examples
tags:
  - linux
  - toolbox
---

## Watch the array status

{{< highlight sh >}}
watch -d -n10 mdadm --detail /dev/md127
{{< /highlight >}}

## Recovery from livecd

{{< highlight sh >}}
mdadm --examine --scan >> /etc/mdadm.conf
mdadm --assemble --scan /dev/md/root
mount /dev/md127 /mnt  # or vgscan...
{{< /highlight >}}

If auto detection does not work, you can still assemble an array manually :
{{< highlight sh >}}
mdadm --assemble /dev/md0 /dev/sda1 /dev/sdb1 
{{< /highlight >}}

## Resync an array

First rigorously check the output of `cat /proc/mdstat`
{{< highlight sh >}}
mdadm --manage --re-add /dev/md0 /dev/sdb1
{{< /highlight >}}

## Destroy an array

{{< highlight sh >}}
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sda
mdadm --zero-superblock /dev/sdb
{{< /highlight >}}
