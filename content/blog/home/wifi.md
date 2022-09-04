---
title: Bridging and roaming on my home wifi
description: OpenWRT with ethernet/wifi bridging and transparent roaming
date: 2022-08-27
tags:
  - OpenWRT
  - WiFi
---

## Introduction

This article is the third in a series about my home network:
- [part one: My home network]({{< ref "blog/home/home.md" >}})
- [part two: My OpenWRT Routers initial configuration]({{< ref "blog/home/interfaces.md" >}})

If you try to follow this as a guide and something is not clear do not hesitate to shoot me an email asking for clarifications or screenshots!

## Bridged wan

From the `network/interfaces` menu, go to the `devices` tab:
- select `Add device configuration`
- for the `Device type` field, select `Bridge device`
- for the `Device name` field, select `br-wan`
- for the `Bridge ports` field, select `wan`
- return to the `interfaces` tab
- click edit the wan interface
- for the `Device` field, select `br-wan`
- save, then do the same for the wan6 interface
- save and apply your changes

## Bridged wifi

I restrict this network to the 5GHz frequency range for performance reasons. All my laptops and phones support it and I do not want one to fallback silently to the 2.4GHz range. Therefore I will only configure the `radio1` for this wifi.

From the `network/wireless` menu:
- click the `scan` button next to `radio1`
  - take note of the channel numbers you see here that have a significant signal strength
  - in order to chose the best channels, it is important you do this for all the access points you plan to setup: it will avoid reconfiguration in the future that way
- click the `edit` button under `radio1`
- in the `Device configuration` section at the top:
  - select the `operating frequency` this access point will use. I keep to `AC` mode and `80MHz width` for the best performance.
  - 5GHz channels go from 36 to 64, 100 to 144 and 149 to 173 with 20MHz between two channels
  - choose wisely non overlapping 80MHz bands for each of your access points, that also do not overlap with the strong signals you scaned with each device at the beginning of this section. For example, I use 36 on my first access point and 56 on the second.
  - go to the `advanced settings` tab
  - for the `Country code` field, enter the designation of the country where the access point is located. If you do not do it, your wifi will not work at all!
- scroll down to the `Interface configuration` section for a second set of tabs
  - for the `ESSID` field, enter the name you want your wifi network to have. I use `Adyxax` because I am an original!
  - for the `Network` field, select `wan` and maybe `wan6` if your ISP supports it.
  - go to the `wireless security` tab
  - for the `Encryption` field, select the strongest encryption mode supported by all your devices
  - for the `Key` field, enter a [strong password or passphrase](https://xkcd.com/936/)
  - check `802.1r Fast Transition`
  - for the `NAS ID` field, enter a number which needs unique among the access points on your network
  - for the `Mobility Domain`, enter a four characters hexadecimal string which needs to be the same on all the access points on your network
  - for the `FT protocol` field, select `FT over DS`
  - check `Generate PMK locally`
- save and apply your changes
- click the `enable` button under `radio1`

If all went as expected, you should be able to connect wirelessly with your phone and laptop.
