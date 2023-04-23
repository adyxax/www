---
title: "Docker compose predictable bridge"
date: 2018-09-25
description: How to use a predefined bridge with docker compose
tags:
  - docker
---

## The problem

By default, docker-compose will create a network with a randomly named bridge. If you are like me using a strict firewall on all your machines, this just cannot work.

## The fix

For example if your bridge is named docbr1, you need to put your services in `network_mode: “bridge”` and add a custom `network` entry like :

```yaml
version: '3.0'

services:
  sshportal:
    image: moul/sshportal
    environment:
      - SSHPORTAL_DEFAULT_ADMIN_INVITE_TOKEN=integration
    command: server --debug
    depends_on:
      - testserver
    ports:
      - 2222
    network_mode: "bridge"
networks:
  default:
    external:
      name: docbr1
```
