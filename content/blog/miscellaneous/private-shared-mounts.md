---
title: Private and shared mounts
date: 2021-07-30
description: Shared mount subtrees in Linux are a thing and I did not know it
tags:
  - Alpine Linux
  - kubernetes
  - linux
  - toolbox
---

## Introduction

While playing with k3s on Alpine Linux a few weeks ago I stumbled upon a Linux feature that I had no idea existed. I pride myself on the fact that I know quite a lot on Linux's internals so I was surprised to discover only now a mount mechanism that has been in the kernel for more than a decade!

## Why it is mostly unknown

With almost all modern linux distributions you can go without knowing about this because almost all default on a shared subtree for every mounted filesystems. That's the case for debian and its derivative, rhel/centos and its derivatives, even Gentoo!

You can check if that is the case with a command like :
```sh
root@buster:~ # findmnt -o target,propagation /
TARGET PROPAGATION
/      shared
```

But on Alpine which is really security focused you get :
```sh
root@alpine:~ # findmnt -o target,propagation /
TARGET PROPAGATION
/      private
```

## What it means

According to the kernel feature documentation at https://www.kernel.org/doc/Documentation/filesystems/sharedsubtree.txt, it means something about namespace cloning and securing access of subtrees when using mount binds. The security benefit of private mounts seems clear, but not why every distribution defaults to shared mounts so casually... The kernel feature says that mount points default to private but it is not true nowadays.

Shared mount points seem necessary for container operations with docker/containerd and by extension kubernetes so it makes sense to allow subtree sharing in these contexts, but why make it the default? Maybe because manipulating this feature is really clunky! What I mean by that is that it is a great example of a linuxism incoherence (as opposed to the BSD's).

You can manipulate this by passing a flag to the `mount` command like :
```sh
mount --make-shared /
```

Do you notice something? It is not a mount option... Therefore you cannot specify it in the fstab! Why on earth did it get designed this way? You need to either patch your init system or create a local service that will change the mountpoints status afterwards... Thanks Linux!

## In practice

For my k3s experiments on Alpine I need to make shared `/`, and `/sys` too when using calico. I also need `/var/lib/longhorn/` when using [longhorn](https://longhorn.io/docs/). I leave all the other mount points as private and did not encounter further issues.

This gets configured on boot by activating the `local` service with a `/etc/local.d/shared-mount.start` script.
