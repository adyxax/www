---
title: "Steam"
date: 2019-02-16
description: How to make steam work seamlessly on gentoo with a chroot
tags:
  - gentoo
---

I am not using a multilib profile on gentoo (I use amd64 only everywhere), so when the time came to install steam I had to get a little creative. Overall I believe this is the perfect way to install and use steam as it self contains it cleanly while not limiting the functionalities. In particular sound works, as does the hardware acceleration in games. I tried to achieve that with containers but didn't quite made it work as well as this chroot setup.

[Here is the link to the full article describing how I achieved that.]({{< relref "/docs/gentoo/steam.md" >}})
