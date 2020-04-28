---
title: "Busybox web server"
linkTitle: "Busybox web server"
date: 2019-04-16
description: >
  Busybox web server
---

If you have been using things like `python -m SimpleHTTPServer`, here is something even more simple and lightweight to use :

{{< highlight sh >}}
busybox httpd -vfp 80
{{< /highlight >}}
