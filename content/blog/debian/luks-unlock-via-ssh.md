---
title: 'Unlocking a LUKS partition on boot via SSH on Debian'
description: 'A convenient mechanism'
date: '2025-03-07'
tags:
- Debian
---

## Introduction

This article explains how to setup an SSH server intramfs unlock mechanism for a
root filesystem encrypted with LUKS. I have been using this for years but never
documented it!

I am used to the comfort of unlocking the partition thanks to an SSH server
embedded in the initramfs. This setup has the security flaw that the initramfs
could be replaced by a malicious party, but this is not something I am overly
concerned about for my personal stuff so please ignore it.

## Configuration

All this relies on embedding an SSH server inside the initramfs:

``` shell
apt update -qq
apt install dropbear-initramfs -y
```

The dropbear SSH server offers some configuration options through its command line:
``` shell
printf '%s' 'DROPBEAR_OPTIONS="-I 600 -j -k -p 2222 -s -E -m -c /bin/cryptroot-unlock"' >>/etc/dropbear/initramfs/dropbear.conf
printf '%s' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco' >/etc/dropbear/initramfs/authorized_keys
```

Here I set:
- `-I 600`: idle timeout of 10 minutes
- `-j -k`: disable local and remote port forwarding
- `-p 2222`: request port 2222
- `-s`: disable password logins so that only ssh key authentication is available
- `-E`: log to stderr (syslog is not available at this point in the boot process)
- `-m`: disable motd
- `-c /bin/cryptroot-unlock`: enforce a single command, no open shell

A personal preference of mine is to forego the predictable network interface
naming of modern Linux. You can omit this step if you are fine with using
`enp0s3` instead of the simple `eth0`:

``` shell
printf '%s' 'GRUB_CMDLINE_LINUX="net.ifnames=0"' >> /etc/default/grub
update-grub
```

Since this is a server I configure networking statically on this host. Sadly
this initramfs component does not support IPv6 yet:

``` shell
printf '%s' 'IP=37.187.244.19::37.187.244.1:255.255.0.0:myth:eth0' >>/etc/initramfs-tools/initramfs.conf
update-initramfs -k all -u
```

The syntax is a bit obtuse but here are the components of this line that are separated by colons:
- `37.187.244.19`: IP address of the server
- empty: IP address of an NFS server, remnant of network boot protocols that you
  are unlikely to be using
- `37.187.244.1`: Gateway of the server
- `255.255.255.0`: Netmask of the server. Since this initramfs network
  configuration system does not support gateway on link routing, the netmask
  needs to be big enough to encompass your IP address and the one of your
  gateway. For example for another host with IP address `51.77.159.16` and
  gateway `51.77.156.1`, I need a `255.255.252.0` netmask.
- `myth`: hostname of the server
- `eth0`: interface to bring up

## Conclusion

With all this done, I can reboot a server and remote unlock it without having to
open the providers webui and use their clunky virtual KVM interface!
