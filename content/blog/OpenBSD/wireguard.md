---
title: Wireguard on OpenBSD
description: How to configure a wireguard endpoint on OpenBSD
date: 2023-02-15
tags:
- OpenBSD
- vpn
- wireguard
---

## Introduction

This article explains how to configure wireguard on OpenBSD.

I chose to kick off this wireguard series with OpenBSD because it is the cleanest and the better integrated of all operating systems that support wireguard.

## Installation

OpenBSD does things elegantly as usual : where linux distributions have a service, OpenBSD has a simple `/etc/hostname.wg0` file. The interface is therefore managed without any tool other than the standard ifconfig, it's so simple and elegant!

If you want you can still install the usual tooling with:
```sh
pkg_add wireguard-tools
```

## Generating keys

The private and public keys for a host can be generated with the following commands:
```sh
PRIVATE_KEY=`wg genkey`
PUBLIC_KEY=`printf $PRIVATE_KEY|wg pubkey`
echo private_key: $PRIVATE_KEY
echo public_key: $PUBLIC_KEY
```

Private keys can also be generated with the following command if you do not wish to use the `wg` tool:
```sh
openssl rand -base64 32
```

I am not aware of an openssl command to extract the corresponding public key, but after setting up your interface `ifconfig` will kindly show it to you.

## Configuration

Here is a configuration example of my `/etc/hostname.wg0` that creates a tunnel listening on udp port 342 and several peers :
```cfg
wgport 342 wgkey '4J7O3IN7+MnyoBpxqDbDZyAQ3LUzmcR2tHLdN0MgnH8='
10.1.2.1/24
wgpeer 'LWZO5wmkmzFwohwtvZ2Df6WAvGchcyXpzNEq2m86sSE=' wgaip 10.1.2.2/32
wgpeer 'SjqCIBpTjtkMvKtkgDFIPJsAmQEK/+H33euekrANJVc=' wgaip 10.1.2.4/32
wgpeer '4CcAq3xqN496qg2JR/5nYTdJPABry4n2Kon96wz981I=' wgaip 10.1.2.8/32
wgpeer 'vNNic3jvXfbBahF8XFKnAv9+Cef/iQ6nWxXeOBtehgc=' wgaip 10.1.2.6/32
up
```

Your private key goes on the first line as argument to `wgkey`, the other keys are public keys for each peer. As all other hostname interface files on OpenBSD, each line is a valid argument you could pass the `ifconfig` command.

To re-read the interface configuration, use :
```sh
sh /etc/netstart wg0
```

## Administration

The tunnel can be managed with the standard `ifconfig` command:
```sh
root@yen:~# ifconfig wg0
wg0: flags=80c3<UP,BROADCAST,RUNNING,NOARP,MULTICAST> mtu 1420
        index 4 priority 0 llprio 3
        wgport 342
        wgpubkey R4A01RXXqRJSY9TiKQrZGR85HsFNSXxhRKKEu/bEdTQ=
        wgpeer LWZO5wmkmzFwohwtvZ2Df6WAvGchcyXpzNEq2m86sSE=
                wgendpoint 90.66.117.156 1024
                tx: 158515972, rx: 151576036
                last handshake: 93 seconds ago
                wgaip 10.1.2.2/32
        wgpeer SjqCIBpTjtkMvKtkgDFIPJsAmQEK/+H33euekrANJVc=
                wgendpoint 90.66.117.156 51110
                tx: 30969024, rx: 14034688
                last handshake: 9527 seconds ago
                wgaip 10.1.2.4/32
        wgpeer 4CcAq3xqN496qg2JR/5nYTdJPABry4n2Kon96wz981I=
                wgendpoint 90.66.117.156 46247
                tx: 36877516, rx: 19036472
                last handshake: 23 seconds ago
                wgaip 10.1.2.8/32
        wgpeer vNNic3jvXfbBahF8XFKnAv9+Cef/iQ6nWxXeOBtehgc=
                wgendpoint 90.66.117.156 1025
                tx: 150787792, rx: 146836696
                last handshake: 43 seconds ago
                wgaip 10.1.2.6/32
        groups: wg
        inet 10.1.2.1 netmask 0xffffff00 broadcast 10.1.2.255
```

Alternatively you can also use the `wg` tool if you installed it.
