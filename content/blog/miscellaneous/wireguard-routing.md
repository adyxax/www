---
title: Wireguard routing part one
description: The basics to know about wireguard routing
date: 2023-02-21
tage:
- vpn
- wireguard
---

## Introduction

Now that we learned how to configure wireguard on multiple operating systems, let's take a break and review what running wireguard does to your routing table.

## Wireguard routing basics

The most important thing to understand is that you do not configure routes with wireguard: the `AllowedIPs` you configure for a peer become your routes!

This has several consequences:
- These routes are always in your routing table, even when the peer is unreachable.
- If you accept traffic from a range of IPs through wireguard, all traffic towards this range will go through wireguard too.

This is what you want most of the time, but it is cumbersome if you ever:
- want to redirect all your internet traffic through wireguard.
- would like to have redundancy to reach a distant host through more than one wireguard peer.
- want to route all traffic destined to the internet.

## The simplest setup

Let's consider the two hosts and two networks in the following schematic:

![Simplest setup](/static/wireguard-routing-1.drawio.svg)

The first network is physical and connects the eth0 interfaces of the two hosts on `192.168.1.0/24`. The second network is virtual and virtually connects the wg0 wireguard interfaces of the two hosts on `10.1.2.0/24`.

The first host is named Dalinar and has a single physical network interface eth0 with ip address `192.168.1.10/24`. We will configure wireguard with ip address `10.1.2.1/24`, wireguard private key `kIrQqJA1kEX56J9IbF8crSZOEZQLIAywjyoOqmjzjHU=` and public key `zfxxxWIMFYbEoX55mXO0gMuHk26iybehNR9tv3ZwJSg=`.

The second host is named Kaladin and has a single physical network interface eth0 with ip address `192.168.1.20/24`. We will configure wireguard with ip address `10.1.2.2/24`, wireguard private key `SIg6cOoTyJRGIYSZ9ACRryL182yufKAtTLHK/Chb+lo=` and public key `BN89Ckhy4TEHjy37zz/Mvi6cOksnKzHHrnHXx5YkMlg=`.

## Wireguard configurations

Dalinar's wireguard configuration looks like:
```cfg
[Interface]
PrivateKey = kIrQqJA1kEX56J9IbF8crSZOEZQLIAywjyoOqmjzjHU=
ListenPort = 342
Address = 10.1.2.1/32

[Peer]
PublicKey = BN89Ckhy4TEHjy37zz/Mvi6cOksnKzHHrnHXx5YkMlg=
Endpoint = 192.168.1.20:342
AllowedIPs = 10.1.2.2/32
```

Kaladin's wireguard configuration looks like:
```cfg
[Interface]
PrivateKey = SIg6cOoTyJRGIYSZ9ACRryL182yufKAtTLHK/Chb+lo=
ListenPort = 342
Address = 10.1.2.2/32

[Peer]
PublicKey = zfxxxWIMFYbEoX55mXO0gMuHk26iybehNR9tv3ZwJSg=
Endpoint = 192.168.1.10:342
AllowedIPs = 10.1.2.1/32
```

## Important things to note

Look carefully at the netmask in the `Address` and `AllowedIPs`: I did not use `/24` anywhere! I did this because:
- wireguard does not need it.
- it would become confusing with many peers.
- we should try and keep the cleanest routing tables possible.

I could have used a `/24` netmask for the `Address` field, this would work and look natural as this is how all networking devices usually work. I do not because I do not want the OS to have a `/24` route to the wg0 interface without a next hop, I will need it when we introduce a distant host to our configuration in the next article.

I could have put one for the AllowedIPs though, but this would only work in this particular case. As soon as you add more than one peer the configuration would break.

A key takeaway is this: Even though with other vpn solutions (or traditional networking) we are used to have hosts logically sharing a network like `10.1.2.0/24` in our case, this is absolutely not a wireguard requirement. We could have used `10.1.2.1` for Dalinar's wg0 and `172.16.0.1` for Kaladin's wg0 and besides changing these IPs the configuration would be exactly the same and work directly. Let that sink in!

## Routing tables

With this setup if Dalinar was a Linux, its routing table would looks like this with `ip -4 r`:
```
10.1.2.2 dev wg0 scope link
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.10 metric 600
```

Kaladin's would look very similar:
```
10.1.2.1 dev wg0 scope link
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.20 metric 600
```