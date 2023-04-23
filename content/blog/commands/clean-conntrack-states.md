---
title: "Clean conntrack states"
date: 2018-03-02
description: How to clean conntrack states
tags:
  - linux
---

## A not so simple command

Firewalling on linux is messy, here is an example of how to clean conntrack states that match a specific query on a linux firewall :

```sh
conntrack -L conntrack -p tcp –orig-dport 65372 | \
while read _ _ _ _ src dst sport dport _; do
    conntrack -D conntrack –proto tcp –orig-src ${src#*=} –orig-dst ${dst#*=} \
              –sport ${sport#*=} –dport ${dport#*=}
 done
```
