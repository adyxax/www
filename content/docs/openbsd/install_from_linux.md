---
title: Install OpenBSD from linux
description: How to install OpenBSD at hosting providers that do not support it
tags:
- OpenBSD
---

## Introduction

This article explains a simple method to install OpenBSD when all you have is a linux and a remote console.

## How to

First login as root on the linux you want to reinstall as Openbsd then fetch the installer :
{{< highlight sh >}}
curl https://cdn.openbsd.org/pub/OpenBSD/6.8/amd64/bsd.rd -o /bsd.rd
{{< /highlight >}}

Then edit the loader configuration, in this example grub2 :
{{< highlight sh >}}
echo '
menuentry "OpenBSD" {
	set root=(hd0,msdos1)
	kopenbsd /bsd.rd
}' >> /etc/grub.d/40_custom
echo 'GRUB_TIMEOUT=60' >> /etc/default/grub
grub2-mkconfig > /boot/grub2/grub.cfg
{{< /highlight >}}

If you reboot now and connect your remote console you should be able to boot the OpenBSD installer.
