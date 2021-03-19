---
title: Reusing ssh connections
date: 2020-02-05
description: How to speed up opening multiple ssh to a single host
tags:
  - toolbox
---

## Introduction

It is possible to share multiple sessions over a single connection. One of the advantages is that for the duration of the connection, all new sessions open very fast.

## How to

You need a directory to store the sockets for the opened sessions, I use the `~/.ssh/tmp` directory for it. Whatever you choose, make sure it exists by running `mkdir` now. Then add these two lines at the start of your `~/.ssh/config` :
{{< highlight sh >}}
ControlMaster auto
ControlPath   ~/.ssh/tmp/%h_%p_%r
{{< /highlight >}}
