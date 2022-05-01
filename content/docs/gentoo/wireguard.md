---
title: Wireguard
description: How to configure a wireguard endpoint on Gentoo
tags:
- gentoo
- linux
- vpn
---

## Introduction

This article explains how to configure wireguard on Gentoo.

## Installation

```sh
emerge net-vpn/wireguard-tools -q
```

You will also need to set `CONFIG_WIREGUARD=y` in your kernel configuration.

## Generating keys

The private and public keys for a host can be generated with the following commands:
```sh
PRIVATE_KEY=`wg genkey`
PUBLIC_KEY=`printf $PRIVATE_KEY|wg pubkey`
echo private_key: $PRIVATE_KEY
echo public_key: $PUBLIC_KEY
```

## Configuration

Here is a configuration example of my `/etc/wireguard/wg0.conf` that creates a tunnel listening on udp port 342 and has one remote peer:
```cfg
[Interface]
PrivateKey = MzrfXLmSfTaCpkJWKwNlCSD20eDq7fo18aJ3Dl1D0gA=
ListenPort = 342
Address = 10.1.2.7/24

[Peer]
PublicKey = R4A01RXXqRJSY9TiKQrZGR85HsFNSXxhRKKEu/bEdTQ=
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.9/32
PersistentKeepalive = 60
```

To implement this example you will need to generate two sets of keys. The configuration for the first server will feature the first server's private key in the `[Interface]` section and the second server's public key in the `[Peer]` section, and vice versa for the configuration of the second server.

This example is from a machine that can be hidden behind nat therefore I configure a `PersistentKeepalive`. If your host has a public IP this line is not needed.

To activate the interface configuration, use :
```sh
cd /etc/init.d
ln -s wg-quick wg-quick.wg0
rc-update add wg-quick.wg0 default
/etc/init.d/wg-quick.wg0 start
```

## Administration

The tunnel can be managed with the `wg` command:
```sh
root@hurricane:~# wg
interface: wg0
  public key: 7fbr/yumFeTzXwxIHnEs462JLFToUyJ7yCOdeDFmP20=
  private key: (hidden)
  listening port: 342

peer: R4A01RXXqRJSY9TiKQrZGR85HsFNSXxhRKKEu/bEdTQ=
  endpoint: 168.119.114.183:342
  allowed ips: 10.1.2.9/32
  latest handshake: 57 seconds ago
  transfer: 1003.48 KiB received, 185.89 KiB sent
  persistent keepalive: every 1 minute
```
