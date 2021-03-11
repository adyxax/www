---
title: "Find where inodes are used"
linkTitle: "Find where inodes are used"
date: 2018-04-25
description: >
  Find where inodes are used
---

{{< highlight sh >}}
find . -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n
{{< /highlight >}}

