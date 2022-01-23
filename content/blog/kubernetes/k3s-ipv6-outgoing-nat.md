---
title: Calico and outgoing ipv6 traffic on k3s
date: 2022-01-23
description: By default calico does not nat outgoing ipv6 traffic
tags:
  - k3s
  - kubernetes
---

## Introduction

If you followed my [Making dual stack ipv6 work with k3s]({{< ref k3s-ipv6.md >}}) article a few months ago, you ended up with a setup where outgoing ipv6 traffic does not work. I only needed to have my pods reachable from the internet and did not try to generate ipv6 traffic originating from the cluster so never encountered the problem.

One of my kind readers did and reached out to me about the issue : thank you Mo!

## The problem

The problem is that calico does not provide an outgoing nat rule for ipv6 traffic by default as it does for ipv4 traffic. We can see that by inspecting the following :
```sh
# ip6tables -t nat -nvL cali-nat-outgoing
Chain cali-nat-outgoing (1 references)
 pkts bytes target     prot opt in     out     source               destination
```

I did not find a way to fix calico's default ipv6 configuration upon installation, but we can patch it afterwards with `kubectl -n kube-system edit ippools default-ipv6-ippool`. Add "natOutgoing: true" to the spec and calico will generate the necessary nat rule :
```sh
# ip6tables -t nat -nvL cali-nat-outgoing
Chain cali-nat-outgoing (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all      *      *       ::/0                 ::/0
```

This can be automated with the following one liner :
```sh
k -n kube-system patch ippools default-ipv6-ippool --type=merge --patch '{"spec":{"natOutgoing":true}}'
```

With this rule, outgoing ipv6 traffic will work normally!
