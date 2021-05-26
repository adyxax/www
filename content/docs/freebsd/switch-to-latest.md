---
title: Switch from quarterly to latest
description: How to switch your FreeBSD install from the quarterly release cycle to latest
---

## Introduction

I find that the few days I have to wait before a security update that is already available through the FreeBSD latest release cycle before it is also available in quarterly to be a little stressful. I don't really care for the bleeding edge but I would rather have these security updates as soon as possible.

## How to

```
mkdir -p /usr/local/etc/pkg/repos
echo "FreeBSD: { enabled: no }" > /usr/local/etc/pkg/repos/FreeBSD.conf
sed -e 's/^FreeBSD:/latest:/' -e 's/quarterly/latest/'  /etc/pkg/FreeBSD.conf > /etc/pkg/latest.conf
pkg upgrade
```
