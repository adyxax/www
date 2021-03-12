---
title: "Find where inodes are used"
date: 2018-04-25
description: How to locate what is taking all the inodes in the subdirectory of a given device
tags:
  - toolbox
  - unix
---

{{< highlight sh >}}
find . -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n
{{< /highlight >}}
