---
title: My home network
description: wifi setup with transparent roaming
date: 2022-07-24
---

## Introduction

This week I have upgraded my OpenWRT access points. The new release had non compatible changes so I had to wipe the routers and reconfigure everything from scratch. I took the opportunity to document the process and will write at least two blog articles about this. This first one describes my network and the design choices, the second one will be about the OpenWRT configuration to implement these choices.

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

Having your wifi network bridged with your lan is very comfortable if you need to ssh from your workstation to your wifi devices like laptops or phones, especially coupled with the roaming. But devices like TVs, sound bar or game consoles need to go onto an isolated network. It allows me to hide devices from each others on wifi, run dns adblocking on it and ban some weird spying traffic all these "smart" devices do.
