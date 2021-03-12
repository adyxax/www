---
title: "Find hardlinks to a same file"
date: 2018-03-02
description: How to list hardlinks that link to the same file
tags:
  - toolbox
  - unix
---

{{< highlight sh >}}
find . -samefile /path/to/file
{{< /highlight >}}
