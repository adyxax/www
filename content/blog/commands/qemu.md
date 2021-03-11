---
title: "Qemu"
date: 2019-06-10
description: Some simple qemu command usage
tags:
  - linux
  - virtualization
---

## Quickly launch a qemu vm with local qcow as hard drive

In this example I am using the docker0 bridge because I do not want to have to modify my shorewall config, but any proper bridge would do : 
{{< highlight sh >}}
ip tuntap add tap0 mode tap
brctl addif docker0 tap0
qemu-img create -f qcow2 obsd.qcow2 10G
qemu-system-x86_64 -curses -drive file=install65.fs,format=raw -drive file=obsd.qcow2 -net nic,model=virtio,macaddr=00:00:00:00:00:01 -net tap,ifname=tap0
qemu-system-x86_64 -curses -drive file=obsd.qcow2 -net nic,model=virtio,macaddr=00:00:00:00:00:01 -net tap,ifname=tap0
{{< /highlight >}}

The first qemu command runs the installer, the second one just runs the vm.

## Launch a qemu vm with your local hard drive

My use case for this is to install openbsd on a server from a hosting provider that doesn't provide an openbsd installer : 
{{< highlight sh >}}
qemu-system-x86_64 -curses -drive file=miniroot65.fs -drive file=/dev/sda -net nic -net user
{{< /highlight >}}

## Ressources

- https://github.com/dodoritfort/OpenBSD/wiki/Installer-OpenBSD-sur-votre-serveur-Kimsufi
