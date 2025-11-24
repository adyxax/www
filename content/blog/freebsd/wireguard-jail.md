---
title: Wireguard jail on FreeBSD
description: How to configure Wireguard in a jail on FreeBSD
date: 2025-11-25
tags:
- FreeBSD
- VPN
- Wireguard
---

## Introduction

One of my readers contacted me with an interesting question regarding Wireguard
on FreeBSD: how to run Wireguard inside a jail instead of on the host. I only
ever ran Wireguard on the host since that's where I centralize all my routing
and firewalling but was curious to explore the question.

## Requirements

Nowadays Wireguard is easier to configure than ever on FreeBSD! But running it
inside a jail needs two things that might not be straightforward: adding the
`if_wg` module to `/boot/loader.conf` and using a `vnet` jail that exposes the
right `devfs` rule set.

I did not take for granted that the `if_wg` kernel module handled jails
properly, so I checked the sources. Good news is that the module seems to have
enough jail specific code to properly handle the network segregation.

### Loader.conf

When running Wireguard on the host, the kernel module is loaded automatically by
an `ifconfig wg0 create` command. While running inside a jail though, this
command will produce the following error message:

``` shell
SIOCIFCREATE2 (wg0): Invalid argument
```

This is because ifconfig inside the jail does not have permissions to load
kernel modules. To work around that, ensure that the module is loaded on boot by
adding the following to `/boot/loader.conf`:

``` shell
if_wg_load="YES"
```

### Vnet jail

A standard vnet jail without special permissions is enough to run Wireguard.
Just make sure to use the same `devfs` statements that I have in my
`/etc/jail.conf.d/wireguard.conf` file:

``` shell
wireguard {
  exec.consolelog = "/var/log/jail_console_${name}.log";

  # PERMISSIONS
  exec.clean;
  mount.devfs;
  devfs_ruleset = 5;

  # HOSTNAME/PATH
  host.hostname = "${name}";
  path = "/usr/local/jails/containers/${name}";

  # NETWORK
  vnet;
  vnet.interface = "${epair}b";
  $id = "154";
  $ip = "10.0.2.${id}/24";
  $gateway = "10.0.2.2";
  $bridge = "bridge0";
  $epair = "epair${id}";
  # ADD TO bridge INTERFACE
  exec.prestart  = "/sbin/ifconfig ${epair} create up";
  exec.prestart += "/sbin/ifconfig ${epair}a up descr jail:${name}";
  exec.prestart += "/sbin/ifconfig ${bridge} addm ${epair}a up";
  exec.start     = "/sbin/ifconfig ${epair}b ${ip} up";
  exec.start    += "/sbin/route add default ${gateway}";
  exec.start    += "/bin/sh /etc/rc";
  exec.stop      = "/bin/sh /etc/rc.shutdown";
  exec.poststop  = "/sbin/ifconfig ${bridge} deletem ${epair}a";
  exec.poststop += "/sbin/ifconfig ${epair}a destroy";
}
```

Make sure to change the jail Id, IP network, gateway and bridge interface name
to match your setup.

### Wireguard

Create the following files inside your jail. An easy way to do that is to start
the jail and exec into it:

``` shell
service jail start wireguard
jexec wireguard sh
```

Wireguard works out of the box on an up to date FreeBSD 14.3 without any
additional packages like `wireguard-tools`. Just set the interface name and IP
address in `/etc/rc.conf`:

``` shell
network_interfaces="wg0"
ifconfig_wg0="inet 10.1.2.18/24"
```

Then add the following to `/etc/start_if.wg0`:

``` shell
ifconfig wg0 create
wg syncconf wg0 /etc/wg0.conf
```

And finally your Wireguard configuration at `/etc/wg0.conf`:

``` shell
[Interface]
PrivateKey = XXXXXX
ListenPort = 342

[Peer]
PublicKey = R4A01RXXqRJSY9TiKQrZGR85HsFNSXxhRKKEu/bEdTQ=
Endpoint = 168.119.114.183:342
AllowedIPs = 10.1.2.9/32
PersistentKeepalive = 60
```

Start or restart your jail, then confirm that Wireguard is running properly
with:

``` shell
jexec wireguard ifconfig wg0
jexec wireguard wg
```

## Conclusion

All this made me think that an interesting next step to take would be to
configure a Wireguard interface on the host, then pass it as the only interface
for a jail instead of a bridge. The ramifications of this sound pretty neat!
