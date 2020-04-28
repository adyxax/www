---
title: "Aggregate images into a video with mencoder"
linkTitle: "Aggregate images into a video with mencoder"
date: 2018-04-30
description: >
  Aggregate images into a video withmencoder
---

## Aggregate png images into a video
{{< highlight sh >}}
mencoder mf://*.png -mf w=1400:h=700:fps=1:type=png -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o output.avi
{{< /highlight >}}

You should use the following to specify a list of files instead of `*.png`:
{{< highlight sh >}}
mf://@list.txt
{{< /highlight >}}

## References

- http://www.mplayerhq.hu/DOCS/HTML/en/menc-feat-enc-images.html
