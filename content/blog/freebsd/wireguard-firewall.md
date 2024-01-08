---
title: Wireguard firewalling on FreeBSD
description: How to configure pf for wireguard on FreeBSD
date: 2023-03-15
tags:
- pf
- vpn
- wireguard
---

## Introduction

There are multiple firewall solutions available on FreeBSD, but I only ever used pf. If you are a ipfw or ipfilter user I am sorry but I trust you will know how to translate the firewalling rules.

## Template for this article

```cfg
scrub in all

table <jails>    persist
table <myself>   const { self }
table <private>  const { 10/8, 172.16/12, 192.168/16, fd00::/8 fe80::/10 }
table <internet> const { 0.0.0.0/0, !10/8, !172.16/12, !192.168/16, ::/0, fe80::/10, !fd00::/8 }

##### Basic rules #####
nat  pass  on  egress  from  <jails>  to  <internet>  ->  (egress:0)
rdr-anchor "rdr/*"
set skip on lo
block return log

##### This firewall #####
block drop in on egress
pass inet proto icmp all icmp-type unreach code needfrag  # MTU path discovery
pass inet proto icmp all icmp-type { echoreq, unreach }   # echo reply
pass inet6 proto icmp6 all

pass in on egress proto tcp from <internet> to <myself> port { ssh, http, https, smtp, smtps, submission }
pass out from <myself> to any
```

A pre-requisite of this configuration is to have set an `egress` group for your egress interface(s) like so in your `/etc/rc.conf`:
```cfg
ifconfig_vtnet0="DHCP group egress"
```

## Client only

With our template, you can already use your wireguard vpn as a client without any changes because of the `pass out from <myself> to any` rule. It cover all outgoing traffic for us:
- egress udp to port 342 (the port we used as example in our previous articles) to establish the tunnel with our peers
- egress from interface wg0 to send packets into the tunnel.
- conveniently, it covers both ipv4 and ipv6

## Reachable client

To make your client reachable over wireguard, add the following:
```
pass in on wg0 from <private> to <myself>
```

## Server

A server's configuration just need to accept wireguard connections in addition of the previous rule:
```cfg
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <myself>
```

## Hub

As seen in a previous routing article, a hub is a server that can route traffic to another one over wireguard:
```cfg
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <private>
```

Note that you will need to have set `gateway_enable="YES"` in your `/etc/sysctl.conf` to route traffic.
