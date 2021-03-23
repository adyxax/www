---
title: kubernetes single node cluster taint
date: 2020-12-06
description: How to schedule worker pods on your control plane node
tags:
  - kubernetes
---

## The solution

On a single node cluster, control plane nodes are tainted so that the cluster never schedules pods on them. To change that run :
{{< highlight sh >}}
kubectl taint nodes --all node-role.kubernetes.io/master-
{{< /highlight >}}

Getting dns in your pods :
{{< highlight sh >}}
add  --cluster-dns=10.96.0.10 to /etc/conf.d/kubelet
{{< /highlight >}}
