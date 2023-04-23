---
title: "SQLite pretty print"
date: 2019-06-19
description: How to pretty print your SQLite output
tags:
  - SQLite
---

## The solution
In `~/.sqliterc` add the following :
```cfg
.mode column
.headers on
.separator ROW "\n"
.nullvalue NULL
```
