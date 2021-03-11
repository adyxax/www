---
title: "Capture a video of your desktop"
linkTitle: "Capture a video of your desktop"
date: 2011-11-20
description: >
  Capture a video of your desktop
---

You can capture a video of your linux desktop with ffmpeg :

{{< highlight sh >}}
ffmpeg -f x11grab -s xga -r 25 -i :0.0 -sameq /tmp/out.mpg
{{< /highlight >}}
