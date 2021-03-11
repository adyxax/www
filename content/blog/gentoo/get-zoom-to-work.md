---
title: "Get zoom to work"
date: 2018-01-02
description: How to get the zoom video conferencing tool to work on gentoo
tags:
  - gentoo
---

## The problem

The zoom video conderencing tool works on gentoo, but since it is not integrated in a desktop environment on my machine (I am running an i3 window manager) I cannot authenticate on the google corporate domain where I work. Here is how to work around that.

## Running the client

{{< highlight yaml >}}
./ZoomLauncher
{{< /highlight >}}

## Working around the "zoommtg address not understood" error

When you try to authenticate you will have your web browser pop up with a link it cannot interpret. You need to get the `zoommtg://.*` thing and run it in another ZoomLauncher (do not close the zoom process that spawned this authentication link or the authentication will fail :
{{< highlight yaml >}}
./ZoomLauncher 'zoommtg://zoom.us/google?code=XXXXXXXX'
{{< /highlight >}}
