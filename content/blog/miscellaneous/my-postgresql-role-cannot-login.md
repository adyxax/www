---
title: "Cannot login role into postgresql"
date: 2015-11-24
description: How to fix a "Cannot login role" error on postgresql
tags:
  - PostgreSQL
---

## The problem

Login is a permission on postgresql, that sometimes is not obvious it can cause issues.

## The solution

Simply log in as postgres or another administrator account and run :
{{< highlight sh >}}
ALTER ROLE "user" LOGIN;
{{< /highlight >}}
