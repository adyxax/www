---
title: "Pulseaudio"
date: 2018-09-25
description: Some pulseaudio commands
tags:
  - linux
---

## The commands

- List outputs : `pacmd list-sinks | grep -e 'name:' -e 'index'`
- Select a new one : `pacmd set-default-sink alsa_output.usb-C-Media_Electronics_Inc._USB_PnP_Sound_Device-00.analog-stereo`
