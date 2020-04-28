---
title: "Investigate memory errors"
linkTitle: "Investigate memory errors"
date: 2018-07-06
description: >
  How to investigate memory errors on a data ONTAP system
---

{{< highlight sh >}}
set adv
system node show-memory-errors -node <cluster_node>
{{< / highlight >}}
