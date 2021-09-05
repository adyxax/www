---
title: "Simple qemu vm"
date: 2021-06-16
description: How to start a simple qemu vm, no gui!
tags:
  - Linux
  - virtualization
---

## Introduction

I know I already blogged about it in 2019 in [this article]({{< ref "qemu.md" >}}) but it is good to refresh one's memory for something so useful. No virt-manager or any other gui required, no complicated networking... It's easy!

## Installation

```sh
qemu-img create -f raw alpine.raw 16G
qemu-system-x86_64 -drive file=alpine.raw,format=raw,cache=writeback \
                   -cdrom Downloads/alpine-virt-3.14.0-x86_64.iso \
                   -boot d -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 1024 -vnc :0 \
                   -device virtio-net,netdev=vmnic -netdev user,id=vmnic
```

Connect to the console with a `vncviewer :0`.

## Afterwards

```sh
qemu-system-x86_64 -drive file=alpine.raw,format=raw,cache=writeback \
                   -boot c -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 1024 -vnc :0 \
                   -device virtio-net,netdev=vmnic -netdev user,id=vmnic
```

## References

  * https://wiki.gentoo.org/wiki/QEMU/Options#Networking
