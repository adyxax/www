---
title: "Sqlite pretty print"
linkTitle: "Sqlite pretty print"
date: 2019-06-19
description: >
  Sqlite pretty print
---

- In ~/.sqliterc :
{{< highlight sh >}}
.mode column
.headers on
.separator ROW "\n"
.nullvalue NULL
{{< /highlight >}}

