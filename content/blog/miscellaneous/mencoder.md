---
title: "Turning images into a video with mencoder"
date: 2018-04-30
description: How to turn images into a video with mencoder
tags:
  - toolbox
---

## Aggregate png images into a video

Example command :
```sh
mencoder mf://*.png -mf w=1400:h=700:fps=1:type=png -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o output.avi
```

You should use the following to specify a list of files instead of `*.png`:
```sh
mf://@list.txt
```

## References

- http://www.mplayerhq.hu/DOCS/HTML/en/menc-feat-enc-images.html
