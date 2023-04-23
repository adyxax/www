---
title: "List active calls on asterisk"
date: 2018-09-25
description: How to show active calls on an asterisk system
tags:
  - asterisk
---

## Using the cli

```sh
watch -d -n1 'asterisk -rx “core show channels”'
```
