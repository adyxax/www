---
title: 'How to increase /dev/shm size on kubernetes'
description: "the equivalent to docker's shm-size flag"
date: '2024-10-02'
tags:
- kubernetes
---

## Introduction

Today I had to find a way to increase the size of the shared memory filesystem offered to containers for a specific workload. `/dev/shm` is a Linux specific `tmpfs` filesystem that some applications use for inter process communications. The defaults size of this filesystem on kubernetes nodes is 64MiB.

Docker has a `--shm-size 1g` flag to specify that. Though kubernetes does not offer a direct equivalent, we can replicate this with volumes.

## Configuration in pod specification

Here are the relevant sections of the spec we need to set:
``` yaml
spec:
  template:
    spec:
      container:
        volume_mount:
          mount_path: "/dev/shm"
          name: "dev-shm"
      volume:
        empty_dir:
          medium: "Memory"
          size_limit: "1Gi"
        name: "dev-shm"
```

## Conclusion

Well it works!
