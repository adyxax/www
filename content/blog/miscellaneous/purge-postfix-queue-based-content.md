---
title: "Purge postfix queue based on email contents"
date: 2009-04-27
description: How to selectively purge a postfix queue based on email contents
tags:
  - toolbox
---

## The problem

Sometimes a lot of spam can acacumulate in a postfix queue.

## The solution

Here is a command that can search through queued emails for a certain character string (here XXX as an example) and delete the ones that contain it :
```sh
find /var/spool/postfix/deferred/ -type f -exec grep -li 'XXX' '{}' \; | xargs -n1 basename | xargs -n1 postsuper -d
```
