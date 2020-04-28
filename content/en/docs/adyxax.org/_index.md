---
title: "adyxax.org"
linkTitle: "adyxax.org"
weight: 1
description: >
  adyxax.org is my personal computer infrastructure. This section details how I built it and why, and how I maintain it.
---

## What is adyxax.org?

adyxax.org is very much like a small personnal cloud of servers hosted here and there. I am using my experience as a
sysadmin to make it all work and provide various services that are useful to me and people that are close to me. As a good sysadmin, I am trying to be lazy and build the most self
maintainable solution, with as little maintenance overhead as possible.

It relies on mostly gentoo (and some optional openbsd) servers interconnected with point to point openvpn links. Services run inside lxd containers and communications between all those services work
thanks to dynamic routing with bird and ospf along those openvpn links.

## Why write about it?

It is a rather unusual infrastructure that I am proud of, and writing about it helps me to reflect on what I built. Gentoo, OpenBSD and LXD is not the most popular combination of
technologies but I leveraged it to build something simple, flexible and I believe somewhat elegant and beautiful.
