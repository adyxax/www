---
title: "LXD"
description: How to setup a LXD server on gentoo
tags:
- gentoo
- linux
---

## Introduction

I have used LXD for many years successfully, I was never satisfied with the docker way of doing container images pulling who knows what from who knows where. Until recently I managed full machine containers running Alpine Linux and was very happy with the simplicity of it.

## Installation

```sh
touch /etc{/subuid,/subgid}
usermod --add-subuids 1000000-1065535 root
usermod --add-subgids 1000000-1065535 root
emerge -q app-emulation/lxd
/etc/init.d/lxd start
rc-update add lxd default
```

## Initial configuration

```sh
myth /etc/init.d # lxd init
Would you like to use LXD clustering? (yes/no) [default=no]:
Do you want to configure a new storage pool? (yes/no) [default=yes]:
Name of the new storage pool [default=default]:
Would you like to connect to a MAAS server? (yes/no) [default=no]:
Would you like to create a new local network bridge? (yes/no) [default=yes]: no
Would you like to configure LXD to use an existing bridge or host interface? (yes/no) [default=no]: yes
Name of the existing bridge or host interface: lxdbr0
Would you like LXD to be available over the network? (yes/no) [default=no]: yes
Address to bind LXD to (not including port) [default=all]: 10.1.0.247
Port to bind LXD to [default=8443]:
Trust password for new clients:
Again:
Invalid input, try again.

Trust password for new clients:
Again:
Would you like stale cached images to be updated automatically? (yes/no) [default=yes]
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]:
```
