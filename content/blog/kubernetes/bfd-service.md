---
title: How to run the BFD protocol on kubernetes for fast BGP convergence
description: Metallb does not support it yet
date: 2021-08-18
tags:
  - kubernetes
---

## Introduction

I am currently playing with metallb for a baremetal setup of mine that sits behind a router/firewall that I cannot reconfigure with kubernetes. I am therefore planning to have it do a static mapping of public ips to virtual ips configured with metallb, a kubernetes service made just for this kind of situation.

Metallb has two ways of advertising its virtual ips to the world. The first one is the layer2 mode and is unsatisfactory to me because metallb does not speak vrrp, therefore the nodes advertise their virtual ips with their own mac addresses. Because of that, failing over when a node fails (even if you drain it gracefully) takes a long time and there is no way to speed it up.

That leaves me with the bgp way of doing this, which works fine as long as there is no abrupt failure of the node the router/firewall is currently routing to. When an abrupt failure happens you get to wait the bgp session timeout before the router/firewall converges. Draining a node works because the bgp session gets properly closed, only abrupt failures are a problem in this mode.

This problem is well known and usually solved with bfd, but according to https://github.com/metallb/metallb/issues/396 it is neither supported nor planned.

## Bird to the rescue

There are not many well known software BFD implementations. There are several github projects but I wanted something robust and well known, and looked to [bird](https://bird.network.cz/) for that. It is an amazing and very robust piece of software that served me well for years and I trust it. It supports BFD, so lets use it!

One easy way to solve the problem would be to install it directly on the nodes, problem solved! But that would be too easy and at this point I wanted to try running BFD as a daemonset and see how it goes from there.

## Making an image

Being packaged in Alpine Linux, I wrote the following script to build an image. As I am learning `buildah` that's what I tried to use here :
```sh
#!/usr/bin/env bash
set -eu
ALPINE_LATEST=$(curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ |
    perl -lane '$latest = $1 if $_ =~ /^<a href="(alpine-minirootfs-\d+\.\d+\.\d+-x86_64\.tar\.gz)">/; END {print $latest}')
if [ ! -e "./${ALPINE_LATEST}" ]; then
        echo "Fetching ${ALPINE_LATEST}..."
        curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/${ALPINE_LATEST} \
             --output ./${ALPINE_LATEST}
fi
ctr=$(buildah from scratch)
buildah add $ctr ${ALPINE_LATEST} /
buildah run $ctr /bin/sh -c 'apk add --no-cache bird'
buildah add $ctr entry-point.sh /
buildah config \
        --author 'Julien Dessaux' \
        --cmd '[ "/usr/sbin/bird", "-d", "-u", "bird", "-g", "bird", "-s", "/run/bird.ctl", "-R", "-c", "/etc/bird.conf" ]' \
        --entrypoint '[ "/entry-point.sh" ]' \
        --port '3784/udp' \
        $ctr
buildah commit $ctr adyxax/bfd
buildah rm $ctr
```

I wrote the following entry-point script to generate the configuration. It needs to be dynamic because we need to add a router id that we will only know from the node running the pod:
```sh
#!/bin/sh
set -eu

printf 'router id %s;\n' ${BIRD_HOST} > /etc/bird.conf
cat /etc/bird-template.conf >> /etc/bird.conf

exec $@
```

## Running the image

The image is publicly available, you can find it in the following manifest. Just remember to check the tags on https://quay.io/repository/adyxax/bfd?tab=tags in case I updated the image for a new Alpine or Bird release.

For now I chose to run bfd from its own namespace :
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: bfd
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: bfd
  name: config
data:
  bird.conf: |
    protocol device {
    }
    protocol direct {
            disabled;               # Disable by default
            ipv4;
            ipv6;
    }
    protocol kernel {
            ipv4 {
                  export all;
            };
    }
    protocol kernel {
            ipv6 { export all; };
    }
    protocol static {
            ipv4;
    }
    protocol bfd firewalls {
      neighbor 10.2.21.1;
      neighbor 10.2.21.2;
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  namespace: bfd
  name: bird
  labels:
    app: bird
spec:
  selector:
    matchLabels:
      app: bfd
  template:
    metadata:
      labels:
        app: bfd
    spec:
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
      containers:
      - name: bfd
        image: quay.io/adyxax/bfd:2021081806
        ports:
        - containerPort: 3784
          hostPort: 3784
          protocol: UDP
          name: bfd
        volumeMounts:
        - name: config-volume
          mountPath: /etc/bird-template.conf
          subPath: bird.conf
        env:
        - name: BIRD_HOST
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.hostIP
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 10"]
        securityContext:
          capabilities:
            add: ["NET_BIND_SERVICE", "NET_RAW", "NET_ADMIN", "NET_BROADCAST"]
      volumes:
      - name: "config-volume"
        configMap:
          name: config
      hostNetwork: true
  updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
```

I took the list of capabilities from bird's source code, and got the inspiration to fetch the host IP address from metallb's daemonset manifest. Given all this, it works perfectly!

## Diagnosing

You can exec in a container and run the bird client from there :
```sh
kubectl -n bfd exec -ti bird-55sl7 -- birdc
BIRD 2.0.8 ready.
bird> show bfd sessions
firewalls:
IP address                Interface  State      Since         Interval  Timeout
10.2.21.1                 eth0       Up         16:51:23.162    1.000    0.000
10.2.21.2                 eth0       Down       16:51:23.162    1.000    0.000
```

## Ideas for improvements

A good first improvement would be to handle BFD authentication.

Another more challenging improvement would be to run this in metallb's namespace and use metallb's configmap to get the peers' IP addresses, and respect the node selector expressions to limit which bird process does what on each node.
