---
title: Wireguard and ipv6
description: "An overview of ipv6 with wireguard: it just works"
date: 2023-02-28
tag:
- ipv6
- vpn
- wireguard
---

## Introduction

In the previous articles I voluntarily omitted to configure ipv6 in order to simplify the examples, let's cover it now.

## Connecting to wireguard over ipv6

This one is easy, just specify an ipv6 endpoint in your peer's configuration:
```cfg
[Interface]
PrivateKey = <private-key>
ListenPort = 342
Address = 10.1.2.10/32

[Peer]
PublicKey = <public-key>
Endpoint = [2a01:4f8:c2c:bcb1::1]:342
AllowedIPs = 10.1.2.0/24
PersistentKeepalive = 60
```

## Running ipv6 traffic through wireguard

For simplicity I revert the endpoint to an ipv4 address in the next examples. It could be an ipv6 address but I want to show you that it is possible to combine settings any way you want.

`fd00::/8` is reserved for private ipv6 addressing, I am therefore using it in several places and you can too:
```cfg
[Interface]
PrivateKey = <private-key>
ListenPort = 342
Address = fd00::2/128

[Peer]
PublicKey = <public-key>
Endpoint = 168.119.114.183:342
AllowedIPs = fd00::1/128
PersistentKeepalive = 60
```

The routing table will be populated in the same fashion as with ipv4 traffic, the same rules we already saw apply in the very same way. Here I shared two `/128` subnets but any subnet size would do as long as you are careful with what you are doing.

To have both ipv4 or ipv6 traffic, separate the routes with a comma:
```cfg
[Interface]
PrivateKey = <private-key>
ListenPort = 342
Address = 10.1.2.10/32, fd00::2/128

[Peer]
PublicKey = <public-key>
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.9/32, fd00::1/128
PersistentKeepalive = 60
```

We can also use public ipv6 addressing, for example to provide ipv6 connectivity to a host whose ISP does not offer it yet (yes, this still happens in 2023!). I will cover this in a next article about this special case of routing all internet traffic through wireguard.