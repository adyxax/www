---
title: "Cleaning a docker host"
date: 2018-01-29
description: How to retrieve storage space by cleaning a docker host
tags:
  - docker
---

## The command

Be careful that this will delete any stopped container and remove any locally unused images, volumes and tags :
```sh
docker system prune -f -a
```
