---
title: My OpenWRT Routers initial configuration
description: ethernet and system
date: 2022-08-01
tags:
  - OpenWRT
---

## Introduction

This article is the continuation of [the previous one]({{< ref "blog/home/home.md" >}}). Since posting I updated the last two paragraphs because I forgot two reasons for my design choices. You might want to read it again since the following articles implement those choices.

If you try to follow this as a guide and something is not clear do not hesitate to shoot me an email asking for clarifications or screenshots!

## Initial configuration

I will assume you just completed a clean installation of OpenWRT from the official documentation, in my case https://openwrt.org/toh/netgear/r6220. With that done, the first step is to plugin a RJ45 cable between your computer and one of the lan ports behind the router.

You should get an address in the `192.168.1.0/24` network through dhcp. With it you can access [the webui](http://192.168.1.1/) and login as `root` by leaving the password field blank. Then go set an admin password from the `system/Administration` menu.

## Interfaces

For my setup I first need to re-address the lan interface of OpenWRT since by default it uses the network subnet I want to use on my LAN. My LAN being what I will connect the wan interface of the OpenWRT router to. It can get confusing: just remember that the wan interface will be the exit point of the traffic going through the router, while lan ports are the one for devices the furthest from the internet.

In order to readdress the lan interface, I cannot be connected to it. Therefore our first step is to setup the wan interface and reconnect to the webui with it:
- edit the wan interface from the `network/interfaces` menu and set a temporary subnet on it, something we won't need to use later for example `172.16.0.1/30`.
- edit the firewall from the `network/firewall` menu to allow INPUT traffic on the wan interface
- save and apply your changes
- unplug your RJ45 cable from its lan port and plug it in the wan port
- configure a static ip on the same subnet you just used for example `172.16.0.2/30`
- you should be able to reconnect to [the webui](http://172.16.0.1/) with these new addresses

Now we can reconfigure the lan interface:
- edit the lan interface and configure its final subnet: I use `192.168.10.1/24`
- save and apply your changes
- unplug your RJ45 cable from the wan port and reconnect it in a lan port
- you should be able to reconnect to [the webui](http://192.168.10.1/) with these new addresses

And finally reconfigure the wan interface:
- edit the wan interface and configure its final subnet: I use `192.168.1.5/24` to address the router with `192.168.1.1` as gateway (the address of my FAI's router on my LAN)
- Save and apply your changes

I leave the INPUT traffic allowed on my firewall because I intend to access my router from my LAN, which means through this interface named wan

## System configuration

It is  a good time to set the `hostname` in the `System/System` menu, as well as your router's timezone. On the Logging tab of this page, I also reconfigure the `log output level` to `INFO` and the `cron log level` to `NORMAL`. NTP should be active for time synchronization, and finally I like to set the webui theme to `BootstrapDark`.

Next, since the router should now have access to the internet through my FAI's router, I head to the `System/Software` menu to add `openssh-server`. It is a requirement for me because the default ssh server is the one from busybox and it does not support `ed25519` ssh keys, only `rsa`. I also install `vim-fuller` for ease of use but if the storage ever gets cramped I would remove it and not miss it.

I then set an ed25519 key through the `System/Administration` menu, in the SSH-Keys tab. It is then a good time to upgrade the packages which changed since the image's release, which I do through ssh:
```sh
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
```

If critical components got upgraded (like busybox or openssl), it is a good idea to reboot the router.
