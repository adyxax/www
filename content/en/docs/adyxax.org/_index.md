---
title: "adyxax.org"
linkTitle: "adyxax.org"
weight: 1
description: >
  adyxax.org is how I call my personal computer infrastructure.
---

## What is adyxax.org?

adyxax.org is how I call my personal computer infrastructure. It is very much like a small personnal private cloud of servers hosted here and there. I am using my experience as a
sysadmin to make it all work and provide various services that are useful to me and people close to me.

It relies on gentoo and openbsd servers interconnected with point to point openvpn links. Services run inside lxd containers and communications between all those services is assured
thanks to dynamic routing with bird and ospf along those openvpn links.

## Why write about it?

It is a rather unusual infrastructure that I am proud of, and writing about it helps me to reflect on what I built. Gentoo, OpenBSD and LXD is not the most popular combination of
technologies but it allowed me to build something simple, flexible and I believe somewhat elegant and beautiful.
