---
title: Install Alpine from another Linux rescue
description: How to install Alpine Linux at hosting providers that do not support it
tags:
- Alpine
- linux
---

## Introduction

This article explains a simple method to install Alpine when all you have is another linux and a remote console.

## How to

First boot on your provider's rescue image. We just need to get a recent alpine-virt installation iso and copy it :
```sh
wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-3.14.0-x86_64.iso
dd if=alpine-virt-3.14.0-x86_64.iso of=/dev/sdb bs=1M
sync
reboot
```

The server should boot on the installation iso, which runs from memory. Connect to your provider's KVM to continue and you will be abble to run a standard installation with :
```sh
setup-alpine
```

Note that in this example on ovh's rescue image, the rescue disk is sda while my server's disk is sdb so that was my dd target. After leaving the rescue my server's disk is sda again.
