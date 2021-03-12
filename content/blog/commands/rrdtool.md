---
title: "rrdtool"
date: 2018-09-25
description: How to graph manually with rrdtool
tags:
  - toolbox
---

## Graph manually

{{< highlight sh >}}
for i in `ls`; do
    rrdtool graph $i.png -w 1024 -h 768 -a PNG --slope-mode --font DEFAULT:7: \
      --start -3days --end now DEF:in=$i:netin:MAX DEF:out=$i:netout:MAX \
      LINE1:in#0000FF:"in" LINE1:out#00FF00:"out"
done
{{< /highlight >}}

## References

- https://calomel.org/rrdtool.html
