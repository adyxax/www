---
title: "mdadm"
date: 2011-11-15
description: some mdadm command examples
tags:
  - linux
  - toolbox
---

## Watch the array status

```sh
watch -d -n10 mdadm --detail /dev/md127
```

## Recovery from livecd

```sh
mdadm --examine --scan >> /etc/mdadm.conf
mdadm --assemble --scan /dev/md/root
mount /dev/md127 /mnt  # or vgscan...
```

If auto detection does not work, you can still assemble an array manually :
```sh
mdadm --assemble /dev/md0 /dev/sda1 /dev/sdb1 
```

## Resync an array

First rigorously check the output of `cat /proc/mdstat`
```sh
mdadm --manage --re-add /dev/md0 /dev/sdb1
```

## Destroy an array

```sh
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sda
mdadm --zero-superblock /dev/sdb
```
