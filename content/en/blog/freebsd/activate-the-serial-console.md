---
title: "Activate the serial console"
linkTitle: "Activate the serial console"
date: 2018-01-03
description: >
  How to activate the serial console
---

Here is how to activate the serial console on a FreeBSD server :
- Append `console=“comconsole”` to `/boot/loader.conf`
- Append or update existing line with `ttyd0` in `/etc/ttys` to : `ttyd0 “/usr/libexec/getty std.9600” vt100 on secure`
