---
title: My home network
description: wifi setup with transparent roaming
date: 2022-07-24
tags:
  - OpenWRT
---

## Introduction

This week I have upgraded my OpenWRT access points. The new release had non compatible changes so I had to wipe the routers and reconfigure everything from scratch. I took the opportunity to document the process and will write a series of blog articles about this. This first one describes my network and the design choices, the following will be about the OpenWRT configuration to implement these choices.
- [part two: My OpenWRT Routers initial configuration]({{< ref "blog/home/interfaces.md" >}})
- [part three: Bridging and roaming on my home wifi]({{< ref "blog/home/wifi.md" >}})

## My home network

This is a simple lan network:

![home network](/static/home.drawio.svg)

My FAI's router acts as a very basic firewall and as a dhcp server for the lan. Most other functionalities are disabled, especially its wifi since I wanted to do cool stuff this router does not support at all.

## The wifi setup

There are two wifi access point on my network. One might just be enough if placed at the center of the house, but I then would have no reception in the garden. Besides I very much prefer having two access points emitting at low power instead of one at high power.

I chose to run OpenWRT on these two access points in order to do the following cool stuff:
- use 802.11r aka transparent roaming
- have one wifi network bridged with my lan
- have a second wifi network isolated from my lan with a restricted firewall and adblocking
- manage the configuration with ansible

Roaming wifi is fantastic once you experience it: never again will your network go down for a few seconds when disconnecting from an access point and reconnecting another. You always have the best signal and your connection never loses a packet!

On top of that, having your wifi network bridged with your lan is very comfortable if like me you need to move around with your laptop and occasionally sit down and plug-in your rj45 cable. With bridging, you just configure the same static ip on both your wired and wireless interfaces and you are good to go! Never again will your ssh connections hang or terminate while moving around.

Devices like TVs, sound bar or game consoles need to go onto an isolated network. It allows me to hide devices from each others on wifi, run dns adblocking on it and ban some weird spying traffic all these "smart" devices do. It is also useful for cheap devices that do not support modern features like my kobo reader or my neato vacuum cleaner: no 5GHz wifi, no WPA3...
