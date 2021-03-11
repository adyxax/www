---
title: "Clean FreeBSD install does not boot"
date: 2018-01-02
description: How to fix a clean install that refuses to boot
tags:
  - FreeBSD
---

## How to fix

I installed a fresh FreeBSD server today, and to my surprise it refused to boot. I had to do the following from my liveUSB :

{{< highlight yaml >}}
gpart set -a active /dev/ada0
gpart set -a bootme -i 1 /dev/ada0
{{< /highlight >}}
