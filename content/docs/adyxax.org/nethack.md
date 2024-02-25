---
title: "nethack"
description: nethack.adyxax.org game server
tags:
- UpdateNeeded
---

## Introduction

I am hosting a private nethack game server accessible via ssh for anyone who will send me a ssh public key. It all runs chrooted on an OpenBSD server.

## dgamelaunch

TODO

```sh
groupadd -r games
useradd -r -g games nethack
git clone 
```

## nethack

TODO

```sh
```

## scores script

TODO

```sh
```

## copying shared libraries

```sh
cd /opt/nethack
for i in `ls bin`; do for l in `ldd bin/$i | tail -n +1 | cut -d'>' -f2 | awk '{print $1}'`; do if [ -f $l ]; then echo $l; cp $l lib64/; fi; done; done
for l in `ldd dgamelaunch | tail -n +1 | cut -d'>' -f2 | awk '{print $1}'`; do if [ -f $l ]; then echo $l; cp $l lib64/; fi; done
for l in `ldd nethack-3.7.0-r1/games/nethack | tail -n +1 | cut -d'>' -f2 | awk '{print $1}'`; do if [ -f $l ]; then echo $l; cp $l lib64/; fi; done
```

## making device nodes

TODO! For now I mount all of /dev in the chroot :
```sh
#mknod -m 666 dev/ptmx c 5 2
mount -R /dev /opt/nethack/dev
```

## debugging

```sh
gdb chroot
run --userspec=nethack:games /opt/nethack/ /dgamelaunch
```
