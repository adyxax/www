---
title: Memory difficulties with nixos
description: Things to be aware of if you are on the fence about switching to nixos
date: 2023-12-14
tags:
- nix
---

## Introduction

I encountered my first difficulties with nixos which required some ingenuity outside of the natural learning curve.

## On memory and lightweight software

The VPS hosts I am using are not really beefy. Three of these only have 1GB of ram which is not a lot by today's standards, but quite sufficient for many usages. The services I self host are quite lightweight so I never had problems when running Alpine Linux, Debian, FreeBSD or OpenBSD on these small machines. Of course k3s was reserved for my beefier 2GB hosts, but nixos seemed it could fit. Like any operating system, it consumes little memory at rest.

The one big memory constraint coming from nixos might not be obvious: it is when rebuilding the configurations! For an almost empty host, very simple configuration and no services besides dhcp, ssh, journal and cron, a nixos configuration build could take about 500MB of ram. That is not negligible but it fit.

With some services like an irc server, eventline, privatebin and gotosocial, the configuration got more complex and nixos more demanding, consuming about 700MB for a build.

## Building nixos remotely

I hit a wall when I started using a second channel to pull more recent packages. I wanted bleeding edge packages for things like Emacs, but stable ones for all the other parts of the system... and I could no longer build nixos locally! 1GB is not enough to have the packages sources and resolve dependencies when building the configuration.

Therefore I started building nixos configurations remotely. My workstation does the heavy lifting of building the configuration then copying all the derivations (target configurations, packages and files) to the hosts.

Activating the configuration still involves a spike of memory consumption on the hosts of about 500MB, but it is less than the 1.2GB it takes to build the configurations. Despite this, I experienced a few painful out of memory when deploying a new configuration. Now I shutdown the most demanding services before deploying, like gotosocial which can sometimes consume 200MB of ram by itself.

## Upgrading to 23.11

I had a bad experience upgrading from 23.05 to the recent 23.11 release. I do not know how the diffs between configurations are calculated by nix, but I could not deploy on my 1GB hosts!

I worked around this by using `dd` to copy the hard drive images and start them in virtual machines locally. This allowed me to upgrade then copy the images the other way. Still, that is a painful process. The back and forth copying involves a similar process than I described to [remount partitions as read-only]({{< ref "installing-nixos-on-a-vps.md" >}}) in a previous article.

## Conclusion

Beware if you intend on using nixos on small machines! I will continue experimenting with nix because it still seems worthwhile and I want to continue learning it, but if I end up switching back to another operating system (be it Alpine, Debian or a BSD) it will be because the configuration build process became too painful to bear.
