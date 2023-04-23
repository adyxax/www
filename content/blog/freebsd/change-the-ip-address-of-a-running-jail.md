---
title: "Change the ip address of a running jail"
date: 2018-09-25
description: How to change the ip address of a running jail
tags:
  - FreeBSD
  - jails
---

## The command

Here is how to change the ip address of a running jail :

```sh
jail -m ip4.addr=“192.168.1.87,192.168.1.88” jid=1
```
