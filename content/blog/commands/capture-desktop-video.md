---
title: "Capture a video of your desktop"
date: 2011-11-20
description: Capture a video of your desktop
tags:
  - ffmpeg
---

## The command

You can capture a video of your linux desktop very easily with ffmpeg :

```sh
ffmpeg -f x11grab -s xga -r 25 -i :0.0 -sameq /tmp/out.mpg
```
