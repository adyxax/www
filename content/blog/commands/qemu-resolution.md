---
title: "How to set the VNC resolution of a QEMU virtual machine"
date: 2025-09-19
description: "Full screen, without borders"
tags:
  - Linux
  - virtualization
---

## Introduction

I last blogged about how to run simple QEMU virtual machines in 2021 in [this
article]({{< ref "qemu-bis.md" >}}). I often use these commands to spawn virtual
machines that I only access via SSH, but it was never for their GUI! Now the
need arose and the necessary bits were harder to piece together than I expected.

## Installation

I updated the VNC and drive sections for modern QEMU flags compared to the last
article:

``` shell
qemu-img create -f raw alpine.raw 16G
qemu-system-x86_64 -drive if=none,id=disk,file=/alpine.raw,format=raw,cache=writeback \                                                                         (base)
                   -device virtio-blk-pci,drive=disk \
                   -cdrom Downloads/alpine.iso \
                   -boot d -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 2048 \
                   -display vnc 127.0.0.1:0 \
                   -device virtio-net,netdev=vmnic \
                   -netdev user,id=vmnic,hostfwd=tcp::10022-:22
```

Connect to the console with a `vncviewer :0`, or if an ssh server is running,
use `ssh -p10022 root@localhost`.

## Post-Installation

We boot from the installed disk and drop the options to mount the ISO image:

``` shell
qemu-system-x86_64 -drive if=none,id=disk,file=/alpine.raw,format=raw,cache=writeback \                                                                         (base)
                   -device virtio-blk-pci,drive=disk \
                   -boot c -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 2048 \
                   -display vnc 127.0.0.1:0 \
                   -device virtio-net,netdev=vmnic \
                   -netdev user,id=vmnic,hostfwd=tcp::10022-:22
```

## How to customize the VNC resolution

You only needs to add an extra line of flags. Just substitute your native
resolution (use `xrandr` on your host machine if you are in doubt about which
values to use) in `xres=...,yres=...`:

``` shell
qemu-system-x86_64 -drive if=none,id=disk,file=/alpine.raw,format=raw,cache=writeback \                                                                         (base)
                   -device virtio-blk-pci,drive=disk \
                   -boot c -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 2048 \
                   -display vnc 127.0.0.1:0 \
                   -device virtio-net,netdev=vmnic \
                   -netdev user,id=vmnic,hostfwd=tcp::10022-:22 \
                   -vga none -device virtio-vga,edid=on,xres=2560,yres=1440
```

## Conclusion

It is good to refresh one's memory for something so simple and useful: no
virt-manager or other tools required, no complicated networking... QEMU is fun
and easy!
