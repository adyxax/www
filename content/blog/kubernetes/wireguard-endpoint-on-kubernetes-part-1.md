---
title: Wireguard endpoint on kubernetes part 1
description: How to expose kubernetes services over wireguard
date: 2023-04-13
tags:
- kubernetes
- wireguard
---

## Introduction

This article explains how I expose kubernetes services over wireguard. There are several way to achieve this, I choose to run a wireguard pod with a nginx proxy.

There are multiple reasons in favor of this design, let's break these down.

## Routing the return traffic

When connecting to a service on your kubernetes cluster through wireguard, the return traffic needs to come back through your vpn. There are multiple ways to achieve this:
- have wireguard run on a fixed host and deploy routes to your wireguard clients' subnet via this host
- nat your traffic
- proxy your traffic

I do not want to tie my vpn to a single host so this rules out solution 1. If this was a big enterprise setup, this could work with a dedicated compute for the vpn (or a pair for redundancy) and it would be a great solution! But it would not be tied to kubernetes which is the point of this article.

Nat or proxy are both good because as far as the pods I connect to are concerned the traffic will originate from another pod on the cluster.

## Overlapping networks for pods and services

Often you inherit your infrastructure and do not have the luxury of building or reinstalling everything from scratch. Sometimes you just did not factor it, or you just applied a default configuration. Sometimes it is just not practical to avoid network overlaps between multiple providers.

There are too many reasons (good or bad) for this to happen, I just take it into account when working on linking networks together with a vpn. Nat is one of the possible solutions, a proxy is another.

## DNS resolution for services on kubernetes

DNS is massively used for the discovery of everything running on kubernetes and is unavoidable. This makes it hard to run a nat setup, hence the proxy solution I chose.

The proxy can perform a DNS lookup each time you connect to a service (or with a very short caching window) and send your traffic to the correct pods even when they move around or restart, changing their IP addresses.

It would be possible to perform the DNS resolution from a resolver running on your vpn client (with unbound for example), but it would only work if you do not have overlapping networks.

## Bonus feature: access managed cloud services

A bonus feature that you might enjoy thanks to wireguard with a proxy is the ability to connect to cloud services outside your cluster, for example managed databases. My use case for this is the provisioning of managed databases using terraform. With this facility you can deploy and manage your terraform resources in the same state quite elegantly.

## Conclusion

Here is a simple schematic of what it looks like:

![Architecture](/static/wireguard-endpoint-on-kubernetes.drawio.svg)

Wireguard's pod will just be running nginx as a reverse proxy. Thanks to wireguard itself being integrated with the linux kernel and able to be namespaced, its setup can be isolated in a privileged init container.

There is a network policy aspect to consider as well as nginx and wireguard's configurations to write, all this will be done in the next article.