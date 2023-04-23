---
title: "Convert a unix timestamp to a readable date"
date: 2011-01-06
description: the -d flag of the date command combined with @timestamp
tags:
  - toolbox
---

## The trick

I somehow have a hard time remembering this simple date flags *(probably because I rarely get to practice it), I decided to write it down here :

```sh
$ date -d @1294319676
Thu Jan 6 13:14:36 GMT 2011
```
