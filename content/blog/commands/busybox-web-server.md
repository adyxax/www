---
title: "Busybox web server"
date: 2019-04-16
description: How to serve static files from only busybox
tags:
  - linux
  - toolbox
---

## The command

If you have been using things like `python -m SimpleHTTPServer` to serve static files in a pinch, here is something even more simple and lightweight to use :

```sh
busybox httpd -vfp 80
```
