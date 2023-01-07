---
title: Exposing a FreeBSD jail through wireguard
description: Migrating my Factorio jail to my home network, routing the traffic from the internet facing vps through wireguard
date: 2023-01-07
tags:
- Factorio
- FreeBSD
- jail
- wireguard
---

## Introduction

In a previous blog article, I detailed how I [run a Factorio linux jail]({{< ref "factorio-server-in-a-linux-jail.md" >}}) on a small vps (1 vcpu and 2G of ram). After some time growing our bases on the same map with a friend, we started to see the limits of this small server. As I do not have a cloud server more powerful, I chose to migrate this to a former home server (4 cores and 8G of ram).

Since it is on my home network and no longer facing the internet, I needed a way to still expose it from the vps and chose to use wireguard and some pf rules to do so:

![factorio on a home server exposed via wireguard](/static/factorio-wireguard.drawio.svg)

## Preparing the home server

All this is automated with ansible for me, but here is a breakdown of the required configuration.

### Jail Networking

I strive for the simplest setup and this jail just needs the legacy loopback interface way of doing things:
```sh
echo 'cloned_interfaces="lo1"' >> /etc/rc.conf
service netif cloneup
```

Many jail tutorials will tell you to configure the jail ips in `/etc/rc.conf` too, this is not what I do. It is difficult to automate and I find that having those ips in the `jails.conf` file is a lot more flexible.

### Wireguard

Installing wireguard is as easy as:
```sh
pkg install wireguard
```

The private and public keys for a host can be generated with the following commands:
```sh
PRIVATE_KEY=`wg genkey`
PUBLIC_KEY=`printf $PRIVATE_KEY|wg pubkey`
echo private_key: $PRIVATE_KEY
echo public_key: $PUBLIC_KEY
```

Here is a configuration example of my `/usr/local/etc/wireguard/wg0.conf` that creates a tunnel listening on udp port 342 and has one remote peer:
```cfg
[Interface]
PrivateKey = MzrfXLmSfTaCpkJWKwNlCSD20eDq7fo18aJ3Dl1D0gA=
ListenPort = 342
Address = 10.1.2.5/24

[Peer]
PublicKey = R4A01RXXqRJSY9TiKQrZGR85HsFNSXxhRKKEu/bEdTQ=
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.2/32
PersistentKeepalive = 60
```

To implement this example you will need to generate two sets of keys. The configuration for the first server will feature the first server's private key in the `[Interface]` section and the second server's public key in the `[Peer]` section, and vice versa for the configuration of the second server.

The `PersistentKeepalive` and `Endpoint` entries are only for the home server, the internet facing vps should not have those.

To activate the interface configuration, use :
```sh
service wireguard enable
echo 'wireguard_interfaces="wg0"' >> /etc/rc.conf
service wireguard start
```

### pf firewall

Here is the `/etc/pf.conf` of my home server. It differs from the one on the internet facing vps because it needs to be reachable from my private network:
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

pass in on egress proto tcp from <private> to <myself> port { ssh, http, https, smtp, smtps, submission }
pass out from <myself> to any

##### VPNs #####
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <myself>
pass out on wg0 from <myself> to <private>
```

### Linux subsystem

```sh
service linux enable
service linux start
```

## Migrating the jail

Migrating the jail was relatively easy. First I needed to stop the jail and unmount the linux filesystems:
```sh
service jail stop factorio
umount /jails/factorio/proc
umount /jails/factorio/sys
```

Then rsync did the trick *(here on the home server) with:
```sh
mkdir /jails
rsync -SHaX factorio.adyxax.org:/jails/factorio /jails/
```

I migrated the linux fstab entries from one server to the other:
```cfg
linprocfs       /jails/factorio/proc  linprocfs       rw,late 0 0
linsysfs        /jails/factorio/sys   linsysfs        rw,late 0 0
```

I mount these filesystems on the home server:
```sh
mount /jails/factorio/proc
mount /jails/factorio/sys
```

I migrated the `/etc/jail.conf.d/factorio.conf` configuration. I needed to adjust the pf prestart rules to include `wg0` in addition to `egress` interface (I keep the egress interface to be able to connect locally too):
```cfg
factorio {
        host.hostname = "factorio";
        path = /jails/$name;
        ip4.addr = 127.0.1.1/32;
        ip6 = "new";
        ip6.addr = fc00::1/128;
        exec.system_user = "root";
        exec.jail_user = "root";
        exec.clean;
        exec.prestart = "ifconfig lo1 alias ${ip4.addr}";
        exec.prestart += "ifconfig lo1 inet6 ${ip6.addr}";
        exec.prestart += "/sbin/pfctl -t jails -T add ${ip4.addr}";
        exec.prestart += "/sbin/pfctl -t jails -T add ${ip6.addr}";
        exec.prestart += "echo \"rdr pass on { egress, wg0 } inet proto udp from any to port 34197 -> ${ip4.addr}\n  rdr pass on { egress, wg0 } inet6 proto udp from any to port 34197 -> ${ip6.addr}\" | pfctl -a rdr/jail-$name -f -";
        exec.poststop = "/sbin/pfctl -t jails -T del ${ip4.addr}";
        exec.poststop += "/sbin/pfctl -t jails -T del ${ip6.addr}";
        exec.poststop += "pfctl -a rdr/jail-$name -F nat";
        exec.poststop += "ifconfig lo1 inet ${ip4.addr} -alias";
        exec.poststop += "ifconfig lo1 inet6 ${ip6.addr} -alias";
        exec.start = "/bin/su - factorio -c 'factorio/bin/x64/factorio --start-server factorio/saves/meganoobase.zip' &";
        exec.stop = "pkill factorio ; sleep 15";
        mount.devfs;
}
```

Here are the necessary bits for `/etc/rc.conf`:
```sh
echo 'jail_enable="YES"
jail_list="factorio"
service jail start factorio
```

## pf forwarding rules on the internet facing vps

There are two nat rules necessary:
```cfg
rdr pass on egress inet proto udp from <internet> to <myself> port 34197 -> 10.1.2.2  # factorio TODO ipv6
nat pass on wg0 inet proto udp from <internet> to 10.1.2.2 port 34197 -> (wg0:0)
```

The first rule rewrites the destination IP of the incoming internet traffic to the wireguard IP of the home server. The second rule rewrites their source IP to the wireguard IP of the internet facing vps.

Since we a routing packets, make sure it is enabled in your `/etc/sysctl.conf`:
```sh
sysctl net.inet.ip.forwarding=1
echo 'net.inet.ip.forwarding=1 >> /etc/sysctl.conf'
```

Here is the whole pf configuration as an reference:
```cfg
scrub in all

table <jails>    persist
table <myself>   const { self }
table <private>  const { 10/8, 172.16/12, 192.168/16, fd00::/8 fe80::/10 }
table <internet> const { 0.0.0.0/0, !10/8, !172.16/12, !192.168/16, ::/0, fe80::/10, !fd00::/8 }

##### Basic rules #####
nat  pass  on  egress  from  <jails>  to  <internet>  ->  (egress:0)
rdr-anchor "rdr/*"
rdr pass on egress inet proto udp from <internet> to <myself> port 34197 -> 10.1.2.2  # factorio TODO ipv6
nat pass on wg0 inet proto udp from <internet> to 10.1.2.2 port 34197 -> (wg0:0)
set skip on lo
block return log

##### This firewall #####
block drop in on egress
pass inet proto icmp all icmp-type unreach code needfrag  # MTU path discovery
pass inet proto icmp all icmp-type { echoreq, unreach }   # echo reply
pass inet6 proto icmp6 all

pass in on egress proto tcp from <internet> to <myself> port { ssh, http, https, smtp, smtps, submission, 1337 }
pass out from <myself> to any

##### VPNs #####
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <myself>
pass out on wg0 from <myself> to <private>
```

## Conclusion

I love FreeBSD and I love wireguard: it all works perfectly. This blog post is rather long because I got caught up detailing everything, but if something is unclear or if some piece seems missing do not hesitate to [contact me]({{< ref "about-me.md" >}}#how-to-get-in-touch).
