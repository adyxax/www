---
title: Wireguard routing part two
description: An advanced example
date: 2023-02-23
tage:
- vpn
- wireguard
---

## Introduction

Now that we learned how routing depends on the allowed IPs in the configuration of an host is what populate its routing table and the consequences of it, let's look at a more complex setup with two hosts on a home network and three servers somewhere in the cloud. The servers will all be connected together in a full mesh, but only one of the cloud server will behave like a hub and centralize the home clients' connections.

## Schematic

![Advanced setup](/static/wireguard-routing-2.drawio.svg)

## Home network

Adolin and Baon are how two clients on a home network. They only connect to Elend but will need to be able to reach Cody and Dalinar.

Adolin's configuration:
```cfg
[Interface]
PrivateKey = <adolin-private-key>
ListenPort = 342
Address = 10.1.2.10/32

[Peer]
PublicKey = <elend-public-key>
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.0/24
PersistentKeepalive = 60
```

Baon's configuration:
```cfg
[Interface]
PrivateKey = <baon-private-key>
ListenPort = 343
Address = 10.1.2.20/32

[Peer]
PublicKey = <elend-public-key>
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.0/24
PersistentKeepalive = 60
```

The first important thing to note is that I did not use the same ListenPort for my two hosts. This is because cheap routing firewall at home often do not nat outgoing udp traffic well with long live sessions and I had issues in the past because of this. You can use the same port for both your hosts, but being cautious with udp outgoing traffic is a habit on I took on years ago.

Also I am using an AllowedIPs with a `/24` netmask in order to be able to reach every host in the network. If I wanted for the clients to only be able to reach the servers, I could have either listed all `/32` IPs or used another netmask like `10.1.2.0/29` (`sipcalc` is your friend). Another option would be to use different addressing schemes entirely.

Finally you might have noticed the `Persistentkeepalive`, this is to maintain connectivity with Elend even in the absence of traffic. It is a good thing for hosts behind NAT or road warriors.

## Cloud servers

Cody and Dalinar are two cloud servers in a full mesh with Elend.

Cody's configuration:
```cfg
[Interface]
PrivateKey = <cody-private-key>
ListenPort = 342
Address = 10.1.2.2/32

[Peer]
PublicKey = <elend-public-key>
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.0/24

[Peer]
PublicKey = <dalinar-public-key>
Endpoint = 141.148.230.102:342
AllowedIPs = 10.1.2.3/32
```

Dalinar's configuration:
```cfg
[Interface]
PrivateKey = <dalinar-private-key>
ListenPort = 342
Address = 10.1.2.3/32

[Peer]
PublicKey = <elend-public-key>
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.0/24

[Peer]
PublicKey = <cody-public-key>
Endpoint = 51.77.159.16:342
AllowedIPs = 10.1.2.2/32
```

Here the netmasks can get confusing but it is crucial to get it right. Since we want to be both reachable and able to reach all hosts we need to either give elend a big AllowedIPs netmask or list them all. But since we want to be able to reach the other server, we need to give it its `/32` to have a most specific route in the routing table.

If we wanted to restrict which host can talk to another, listing the wireguard IPs would work perfectly.

Also between servers with fixed endpoints we do not need keepalives.

## Hub's configuration

Here is Elend's configuration:
```cfg
[Interface]
PrivateKey = <elend-private-key>
ListenPort = 342
Address = 10.1.2.1/32

[Peer]
PublicKey = <adolin-public-key>
AllowedIPs = 10.1.2.10/32

[Peer]
PublicKey = <baon-public-key>
AllowedIPs = 10.1.2.20/32

[Peer]
PublicKey = <cody-public-key>
Endpoint = 51.77.159.16:342
AllowedIPs = 10.1.2.2/32

[Peer]
PublicKey = <dalinar-public-key>
Endpoint = 141.148.230.102:342
AllowedIPs = 10.1.2.3/32
```

You might have feared this would be the most complicated configuration but it is the simplest: every peer has a `/32` netmask. The only thing to note is that we do not specify an endpoint for Adolin and Baon since they are behind a home network's NAT.

The only additional thing we need is to enable routing on Elend so that it can forward traffic (firewalling is the subject of the next article). This can be done by setting the right sysctl value depending on your operating system:
- FreeBSD: set `gateway_enable="YES"` in your `/etc/rc.conf`
- Linux: set `net.ipv4.ip_forward=1` in your `/etc/sysctl.conf`
- OpenBSD: set `net.inet.ip.forwarding=1` in your `/etc/sysctl.conf`

## Routing tables

With this setup if Adolin was running Linux, its routing table would look like this with `ip -4 r`:
```
default via 192.168.1.1 dev eth0 proto static metric 600
10.1.2.0/24 dev wg0 scope link
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.10 metric 600
```

Baon's would look very similar:
```
default via 192.168.1.1 dev eth0 proto static metric 600
10.1.2.0/24 dev wg0 scope link
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.20 metric 600
```

Cody's would be a little more complex with overlapping routes:
```
default via XXX
10.1.2.0/24 dev wg0 scope link
10.1.2.3 dev wg0 scope link
```

Dalinar's would look very similar:
```
default via YYY
10.1.2.0/24 dev wg0 scope link
10.1.2.2 dev wg0 scope link
```

Elend's would be longer but simple:
```
default via ZZZ
10.1.2.2 dev wg0 scope link
10.1.2.3 dev wg0 scope link
10.1.2.10 dev wg0 scope link
10.1.2.20 dev wg0 scope link
```

With this setup, every host can contact every other one using wireguard.