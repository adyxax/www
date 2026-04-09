---
title: Toying with OSPF over Wireguard on FreeBSD
description: Some lessons learned
date: 2026-04-10
tags:
- Bird
- FreeBSD
- OSPF
- wireguard
---

## Introduction

For almost a decade, I have been operating my own mesh overlay network using a
combination of point to point OpenVPN tunnels with OSPF on top. It was well
automated with Ansible and served me well all these years.

I decided it was time I tried to move this to Wireguard instead and spent a bit
of time making it all work. This article does not explain everything I did, but
will present some lessons I learned in the process.

## Routing OSPF over Wireguard

By default, Wireguard encourages you to only allow the minimum set of IP
prefixes over a Wireguard tunnel. It filters only that traffic, and conveniently
populates a host's routing table with static routes to the tunnel for each
allowed prefix.

Wireguard also supports configuring multiple peers for a single Wireguard
interface which is very convenient, but sadly cannot work with OSPF. Wireguard
uses the allowed IP prefixes to decide which peer will receive a packet, and
this is incompatible with a protocol that relies on multicast traffic in order
to work. I therefore need one Wireguard interface per peer over which to run
OSPF.

Also since I need to route traffic for dynamically learned routes, the allowed
IP filters pretty much need to be `0.0.0.0/0, ::/0` and cover everything. In
practice I could also use the more restrictive `10/8, 172.16/12, 192.168/16,
224.0.0.5, 224.0.0.6, fd00::/8, fe80::/10, ff02::5, ff02::6`.

Since I cannot have Wireguard insert multiple identical routes for all my
Wireguard interfaces, I also need to disable this functionality. When using the
popular `wg-quick` method, one needs to add `Table = off` to the `[Interface]`
configuration. The native implementations do not need this, it is really only
for `wg-quick`.

My FreeBSD `/etc/start_if.wg0` config therefore looks like:

``` shell
ifconfig wg0 create up description "laptop"
ifconfig wg0 inet 172.31.254.0/31
ifconfig wg0 inet6 fd00:172:31:254::/127
ifconfig wg0 inet6 fe80::/64
wg syncconf wg0 /etc/wg0.conf
```

And the corresponding `/etc/wg0.conf` looks like:

``` shell
[Interface]
PrivateKey = gFAoJwJSfA0A8g+FhfxHLWXj6+CZdmPH4EW5pghqv30=
ListenPort = 342

[Peer]
PublicKey = bAg8bmMQxPFoNSG+Qq2VteCW4VUsi//VleBQBNa5Mno=
AllowedIPs = 0.0.0.0/0,::/0
```

## FreeBSD vs Linux bridge and wireguard interfaces

On FreeBSD, I had a little trouble making OSPF v3 (for IPv6) work on a detached
bridge interface (that I use for VNET jails), and on a wireguard interface.

The problem was that FreeBSD does not generate link-local IPv6 addresses for
these kinds of interfaces, because they are not backed by a MAC address. And it
turns out that the Bird routing daemon needs these link-local IPv6 addresses in
order to work in point-to-point mode!

Luckily these are in effect point-to-point interfaces, so it matters very little
which link-local address I set manually. I just used `fe80::/64` everywhere and
it worked.

Linux does not have this issue and will assign random link-local addresses to
all its interfaces which really made this a confusing debugging session.

## Some PF configuration rules

While not something I learned this time around, I will record here that one can
allow OSPF traffic via PF with:

``` shell
table <myself>   const { self }
table <private>  const { 10/8, 172.16/12, 192.168/16, fd00::/8, fe80::/10 }

pass out from <myself> to any

pass on { wg0, wg1 } from <private> to <private>
pass on { wg0, wg1 } proto ospf allow-opts
```

## Some Bird configuration

Here is a basic Bird3 configuration to reproduce my setup:

``` shell
log syslog all;

router id 172.31.253.1;

protocol device {
}

protocol direct {
    disabled;
    ipv4;
    ipv6;
}

protocol kernel {
    ipv4 { export all; };
    persist;
}

protocol kernel {
    ipv6 { export all; };
    persist;
}

protocol static { ipv4; }

protocol ospf v2 ospf4 {
    area 0 {
        interface "bridge0" { stub; };
        interface "wg0" { bfd yes; cost 100; type ptp; };
        interface "wg1" { bfd yes; cost 100; type ptp; };
    };
}

protocol ospf v3 ospf6 {
    area 0 {
        interface "bridge0" { stub; };
        interface "wg0" { bfd yes; cost 100; type ptp; };
        interface "wg1" { bfd yes; cost 100; type ptp; };
    };
}

protocol bfd {
    interface "wg*" {};
}
```

## Conclusion

I cannot say yet if I will rewrite my Ansible automation for OSPF over
Wireguard, but I certainly had fun figuring these out. I will probably toy with
BGP again next, just because it is also "fun" to redistribute routes this way.
