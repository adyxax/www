---
title: Wireguard
description: How to configure a wireguard endpoint on OpenBSD
---

## Introduction

OpenBSD does things elegantly as usual : where linux distributions have a service, OpenBSD has a simple `/etc/hostname.wg0` file. The interface is therefore managed without any tool other than the standard ifconfig, it's so simple and elegant!

## Configuration example

Here is a configuration example to create a tunnel listening on udp port 342 and several peers :
{{< highlight cfg >}}
wgport 342 wgkey '4J7O3IN7+MnyoBpxqDbDZyAQ3LUzmcR2tHLdN0MgnH8='
10.1.2.1/24
wgpeer 'LWZO5wmkmzFwohwtvZ2Df6WAvGchcyXpzNEq2m86sSE=' wgaip 10.1.2.2/32
wgpeer 'SjqCIBpTjtkMvKtkgDFIPJsAmQEK/+H33euekrANJVc=' wgaip 10.1.2.4/32
wgpeer '4CcAq3xqN496qg2JR/5nYTdJPABry4n2Kon96wz981I=' wgaip 10.1.2.8/32
wgpeer 'vNNic3jvXfbBahF8XFKnAv9+Cef/iQ6nWxXeOBtehgc=' wgaip 10.1.2.6/32
{{< /highlight >}}

Your private key goes on the first line as argument to `wgkey`, the other keys are public keys for each peer.

To re-read the interface configuration, use :
```sh
sh /etc/netstart wg0
```

## Administration

Private keys can be generated with the following command :
{{< highlight sh >}}
openssl rand -base64 32
{{< /highlight >}}

The tunnel can be managed with the standard `ifconfig` command:
{{< highlight sh >}}
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
{{< /highlight >}}
