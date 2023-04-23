---
title: pf.conf
description: The template I use on new installations
tags:
- OpenBSD
- pf
---

## pf.conf

The open ports list is refined depending on the usage obviously, and not all servers listen for wireguard... It is just a template :

```cfg
vpns="{ wg0 }"

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

##### VPNs #####
pass in on egress proto udp from <internet> to <myself> port 342
pass in on $vpns from <private> to <myself>

##### Openbsd stock rules #####
# By default, do not permit remote connections to X11
block return in on ! lo0 proto tcp to port 6000:6010
# Port build user does not need network
block return out log proto {tcp udp} user _pbuild
```
