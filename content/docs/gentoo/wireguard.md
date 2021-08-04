---
title: Wireguard
description: How to configure a wireguard endpoint on Gentoo
---

## Introduction

This article explains how to configure wireguard on Gentoo.

## Configuration example

Here is a `/etc/wireguard/wg0.conf` configuration example to create a tunnel listening on udp port 342 and a remote peers :
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

Your private key goes on the first line as argument to `wgkey`, the other keys are public keys for each peer. In this example I setup a client that can be hidden behind nat therefore I configure a `PersistentKeepalive`. If your host has a public IP this line is not needed.

To activate the interface configuration, use :
```sh
cd /etc/init.d
ln -s wg-quick wg-quick.wg0
rc-update add wg-quick.wg0 default
/etc/init.d/wg-quick.wg0 start
```

## Administration

Private keys can be generated with the following command :
{{< highlight sh >}}
openssl rand -base64 32
{{< /highlight >}}

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
