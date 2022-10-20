---
title: How to setup a Fujitsu Scansnap S1300i on Gentoo Linux
description: My installation notes
date: 2022-10-20
tags:
- Gentoo
- linux
---

## Introduction

I just got myself a document scanner in order to digitalise some documents before I lose them for good. The linux setup required some google-fu so here is a report of what I had to do to get it working.

## Installation notes

I did not need to change anything to my kernel configuration, that was nice!

I installed the following new packages (the `SANE_BACKEND` variable should be added to your `make.conf`):
```sh
SANE_BACKENDS="epjitsu"  emerge  media-gfx/sane-backends  media-gfx/simple-scan  -q
```

Your user should be in the `scanner` and `usb` groups:
```sh
gpasswd -a <username> scanner
gpasswd -a <username> usb
```

A `fujitsu` `SANE_BACKEND` exists, but it is a trap, you really need the `epjitsu` one. Simple-scan is a simple gnome application which is very simple to use. I first tried xsane but it was not user friendly at all!

## The tricky part

Nothing worked at this stage, the scanner was not detected by neither `simple-scan` nor `scanimage -L`, but `sane-find-scanner` could see it just fine. That is because we are missing a firmware which can be found on the [web archive](https://web.archive.org/web/20190217094259if_/https://www.josharcher.uk/static/files/2016/10/1300i_0D12.nal). Download this file then put it as root in `/usr/share/sane/epjitsu/`:
```sh
mkdir -p /usr/share/sane/epjitsu/
mv  /home/julien/Downloads/1300i_0D12.nal  /usr/share/sane/epjitsu/1300i_0D12.nal
```

If you already plugged your scanner before copying this firmware file, unplug it then plug it again and everything should now work. Just launch `simple-scan` and enjoy your scanner!
