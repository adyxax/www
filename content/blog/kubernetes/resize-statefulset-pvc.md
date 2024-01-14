---
title: How to resize the persistent volumes of a kubernetes statefulset
description: kubernetes is a convoluted beast
date: 2024-01-15
tags:
- kubernetes
---

## Introduction

Kubernetes statefulsets are great but they come with their share of limitations. One of those limitations is that you cannot edit or patch many important keys of the YAML spec of an object after it has been created, in particular the requested volume size of the `volumeClaimTemplates`.

## How to

The work around consists of deleting the statefulset while leaving the objects created from it intact. In my example, I am resizing the persistent disks for a redis cluster created with the chart from bitnami, from 1GB to 2GB. It lives on a cluster named `myth` in the namespace `redis`. The statefulset is named `redis-node` and spawns three pods and three pvcs.

### Storage class

First of all you need to ensure the storage class of the persistent volumes supports volume expansion. Most CSI drivers do, but the storage class do not necessarily have it enabled.

To get the storage class to look for you can use (`k` is my shell alias to the `kubectl` command):
```sh
k --context myth -n redis get pvc redis-data-redis-node-0 -o jsonpath='{.spec.storageClassName}'
```

Let's say that the storage class is named `standard`, one of the builtin ones when installing a kubernetes cluster on gcp. Let's inspect it:
```sh
k --context myth get storageclass standard -o jsonpath='{.allowVolumeExpansion}'
```

If you get `false` or an empty output then your storage class is missing a `allowVolumeExpansion: true`. If that is the case, you need to patch your storage class with:
```sh
k --context myth patch storageclass standard --patch '{"allowVolumeExpansion": true}'
```

Note that this object is not namespaced, you are changing this for your whole cluster.

### Resizing the persistent volumes

Resize the pvcs:
```sh
k --context myth -n redis patch pvc redis-data-redis-node-0 --patch '{"spec": {"resources": {"requests": {"storage": "2Gi"}}}}'
k --context myth -n redis patch pvc redis-data-redis-node-1 --patch '{"spec": {"resources": {"requests": {"storage": "2Gi"}}}}'
k --context myth -n redis patch pvc redis-data-redis-node-2 --patch '{"spec": {"resources": {"requests": {"storage": "2Gi"}}}}'
```

### Recreate the statefulset

Get the statefulset:
```sh
k --context myth -n redis get statefulset redis-node -o YAML > redis-statefulset.yaml
```

Edit this yaml file to change the size in the volumeClaimTemplates, remove the status keys (and their values) in the file.

With this yaml file ready, we can remove the statefulset without deleting the other kubernetes objects it spawned:
```sh
k --context myth -n redis delete statefulset redis-node  --cascade=orphan
```

Recreate the statefulset from the modified yaml:
```sh
k --context myth -n redis apply -f redis-statefulset.yaml
```

Beware that this last action will restart the pods.

## Conclusion

Kubernetes is a convoluted beast, not everything makes sense. Hopefully this work around will be useful to you until the day the developers decide it should be reasonable to be able to resize persistent volumes of statefulsets directly.
