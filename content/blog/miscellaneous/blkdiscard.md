---
title: How to discard a whole ssd
date: 2021-08-04
description: How to discard ssd partitions, and not just mounted devices
tags:
  - linux
---

## Introduction

You are probably aware already that Solid State Drives are affected by wear and tear. One of the mechanisms to manage this is to make sure your operating system properly discards unused sectors when deleting files.

## Automatic discards

There are multiple ways to do this automatically, for example :
- cryptsetup has the `--allow-discards` flag
- lvm has an `issue_discards` option in lvm.conf
- standard partition can be mounted with the `discard` mount option

The root partition is a special case when encrypted, for example on Gentoo the cryptsetup flag is passed by genkernel with the non standard `root_trim=yes` on the grub's kernel command line. Other linux distributions will differ in this regard.

## Manual discards

If some of your ssd's discards were not issued for one reason or another, you can run a manual discard job on your mounted filesystems with :
```
fstrim -a
```

But what if you need to do this for a drive or partition that is not mounted? That's what I discovered today and triggered me writing this post : enter `blkdiscard` which like its name suggests, manipulates block devices :
```
blkdiscard /dev/sda
```
