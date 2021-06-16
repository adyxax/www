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
                   -net user -boot d -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 1024 -vnc :0
```

Connect to the console with a `vncviewer localhost`.

## Afterwards

```sh
qemu-system-x86_64 -drive file=alpine.raw,format=raw,cache=writeback \
                   -net user -machine type=q35,accel=kvm \
                   -cpu host -smp 2 -m 1024 -vnc :0
```
