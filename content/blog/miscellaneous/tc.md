---
title: Traffic shaping with tc
date: 2019-09-17
description: How to use the tc command to shape traffic on linux
tags:
  - linux
---

## How to

```sh
tc qdisc show dev eth0
tc qdisc add dev eth0 root netem delay 200ms
tc qdisc show dev eth0

tc qdisc delete dev eth0 root netem delay 200ms
tc qdisc show dev eth0
```

## References

  - https://www.badunetworks.com/traffic-shaping-with-tc/
