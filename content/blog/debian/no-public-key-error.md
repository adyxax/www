---
title: "Fix the no public key available error"
date: 2016-01-27
description: How to fix this common debian error when using non official repositories
tags:
  - Debian
---

## How to fix

Here is how to fix the no public key available error :
```sh
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEYID
```
