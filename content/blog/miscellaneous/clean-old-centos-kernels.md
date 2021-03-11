---
title: "Clean old centos kernels"
date: 2016-02-03
description: Clean old centos kernels
tags:
  - Centos
  - rhel
---

## The problem

Centos kernels tend to accumulate unless you clean them regularly.

## The solution

There is a setting in `/etc/yum.conf` that does exactly that : `installonly_limit=`. The value of this setting is the number of older kernels that are kept when a new kernel is installed by yum. If the number of installed kernels becomes greater than this, the oldest one gets removed at the same time a new one is installed.

This cleaning can also be done manually with a command that belongs to the yum-utils package : `package-cleanup –oldkernels –count=2`
