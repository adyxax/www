---
title: "i3dropdown"
date: 2020-01-23
description: How to use i3dropdown to pump up your graphical environment
tags:
  - linux
  - toolbox
---

## Introduction

i3dropdown is a tool to make any X application drop down from the top of the screen, in the famous quake console style back in the day.

## Compilation

First of all, you have get i3dropdown and compile it. It does not have any dependencies so it is really easy :
{{< highlight sh >}}
git clone https://gitlab.com/exrok/i3dropdown
cd i3dropdown
make
cp build/i3dropdown ~/bin/
{{< /highlight >}}

## i3 configuration

Here is a working example of the pavucontrol app, a volume mixer I use :
{{< highlight conf >}}
exec --no-startup-id i3 --get-socketpath > /tmp/i3wm-socket-path
for_window [instance="^pavucontrol"] floating enable
bindsym Mod4+shift+p exec /home/julien/bin/i3dropdown -W 90 -H 50 pavucontrol pavucontrol-qt
{{< /highlight >}}

To work properly, i3dropdown needs to have the path to the i3 socket. Because the command to get the socketpath from i3 is a little slow, it is best to cache it somewhere. By default
i3dropdown recognises `/tmp/i3wm-socket-path`. Then each window managed by i3dropdown needs to be floating. The last line bind a key to invoke or mask the app.
