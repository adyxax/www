---
title: "omreport"
date: 2018-03-05
description: Some omreport command examples
tags:
  - linux
---

## Your raid status at a glance

- `omreport storage pdisk controller=0 vdisk=0|grep -E '^ID|State|Capacity|Part Number'|grep -B1 -A2 Failed`

## Other commands

{{< highlight sh >}}
omreport storage vdisk
omreport storage pdisk controller=0 vdisk=0
omreport storage pdisk controller=0 pdisk=0:0:4
{{< /highlight >}}
