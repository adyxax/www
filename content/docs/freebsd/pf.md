---
title: pf.conf
description: The template I use on new installations
tags:
- FreeBSD
- firewall
- pf
---

## pf.conf

The open ports list is refined depending on the usage obviously... It is just a template:

```conf
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

##### VPNs #####
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <myself>
pass in on wg0 from <private> to <private>
pass out on wg0 from <private> to <private>
```

A pre-requisite of this sample is to have set an `egress` group for your egress interface(s) like so in your `/etc/rc.conf`:
```conf
ifconfig_vtnet0="DHCP group egress"
```
