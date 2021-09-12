---
title: How to delete all evicted pods in kubernetes
description: A quick note for future reference
date: 2021-09-01
tags:
  - k3s
  - kubernetes
---

## Introduction

I was playing with the percona xtradb operator on one of my test clusters last week and left it in a state where mysqld error logs were piling up over the week-end. On Monday morning my nodes had their file systems full and I discovered what kubernetes evicted pods were : pods that fail when a node's resources get constrained.

My problem is : these evicted pods lingered, so I looked for a way to clean them up.

## How to delete all evicted pods

My google fu directed me towards several commands similar to the following, but they all had a thing or another that did not work properly. Here is the one I pieced together from these various sources :
```sh
kubectl get pods --all-namespaces -o json |
    jq '.items[] | select(.status.reason!=null) |
        select(.status.reason | contains("Evicted")) |
        "kubectl -n \(.metadata.namespace) delete pod \(.metadata.name)"' |
    xargs -n 1 bash -c
```
