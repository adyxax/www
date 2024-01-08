---
title: Wireguard firewalling on OpenBSD
description: How to configure pf for wireguard on OpenBSD
date: 2023-03-04
tags:
- pf
- vpn
- wireguard
---

## Introduction

Now that we covered wireguard configurations and routing, let's consider your firewall configuration in several scenarios. This first article will focus on OpenBSD.

## Template for this article
```cfg
table <myself>   const { self }
table <private>  const { 10/8, 172.16/12, 192.168/16, fd00::/8 fe80::/10 }
table <internet> const { 0.0.0.0/0, !10/8, !172.16/12, !192.168/16, ::/0, fe80::/10, !fd00::/8 }

##### Basic rules #####
set skip on lo
set syncookies adaptive (start 25%, end 12%)
set block-policy return
block drop in log quick from urpf-failed label uRPF
block return log

##### This firewall #####
block drop in on egress
pass in  on egress proto { icmp, icmp6 } from <internet> to <myself>
pass in  on egress proto tcp from <internet> to <myself> port { http, https, imaps, smtp, smtps, ssh, submission }
pass out from <myself>   to any

##### Openbsd stock rules #####
# By default, do not permit remote connections to X11
block return in on ! lo0 proto tcp to port 6000:6010
# Port build user does not need network
block return out log proto {tcp udp} user _pbuild
```

## Client only

With our template, you can already use your wireguard vpn as a client without any changes because of the `pass out from <myself> to any` rule. It cover all outgoing traffic for us:
- egress udp to port 342 (the port we used as example in our previous articles) to establish the tunnel with our peers
- egress from interface wg0 to send packets into the tunnel.
- conveniently, it covers both ipv4 and ipv6

## Reachable client

To make your client reachable over wireguard, add the following:
```cfg
pass in on wg0 from <private> to <myself>
```

Note that your client will typically not have a persistent public ip address, so this will only work if you have a keepalive peer configuration with your peer. If you do not, your peer will only be able to reach you in a short window after you send it traffic. The time this window will remain open will depend of the lifetime of udp states in the firewall that nat your connection to the internet at the edge of your LAN.

In this example I use the `<private>` pf table that I find both very convenient and often sufficient with wireguard: since the tunnel routing is bound to the `AllowedIPs`, nothing unexpected could come or go through the tunnel.

## Server

A server's configuration just need to accept wireguard connections in addition of the previous rule:
```cfg
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <myself>
```

## Hub

As seen in the previous routing article, a hub is a server that can route traffic to another one over wireguard:
```cfg
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <private>
```

Note that you will need to have set `net.inet.ip.forwarding=1` in your `/etc/sysctl.conf` to route traffic.
