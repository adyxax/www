---
title: Static addressing with systemd-networkd
description: Dual IPv4 and IPv6 configuration
date: 2025-03-04
tags:
- systemd
---

## Introduction

I like to keep up with what established operating systems or Linux distributions
are doing even though I am not using them all everyday. While trying out
OpenSUSE again recently, I gave a first try ever to using `systemd-networkd`.

## Configuration

Here is an example of how to configure your network statically with
`systemd-networkd`. The quirk is that there is no way to specify two `Gateway`
attributes in a `Network` block. Since you can have multiple `Address` blocks,
this is an inconsistency that required some reading of the manual before it
clicked.

Here is what ended up working for my `/etc/systemd/network/20-wired.network`:

``` ini
[Match]
MACAddress=fa:16:3e:82:71:b7

[Network]
Address=37.187.244.19/32
Address=2001:41d0:401:3100::fd5/64
DNS=1.1.1.1

[Route]
Destination=0.0.0.0/0
Gateway=37.187.244.1
GatewayOnLink=yes
Metric=10

[Route]
Destination=::/0
Gateway=2001:41d0:401:3100::1
Metric=10
```

The `GatewayOnLink` attribute might not be needed for you. I am using it because
this is an OVH box and this provider likes to reduce instances chatter by
issuing `/32` netmasks on DHCP. Though I could use a more standard netmask in
this static configuration, I choose to respect their preference.

## Conclusion

In the end `systemd-networkd` works well and I have no complaints other than
this quirkiness.
