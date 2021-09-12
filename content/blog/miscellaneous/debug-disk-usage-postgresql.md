---
title: "Investigate PostgreSQL disk usage"
date: 2015-11-24
description: A simple how to
tags:
  - PostgreSQL
---

## How to debug disk occupation in postgresql

- get a database oid number from `ncdu` in `/var/lib/postgresql`
- reconcile oid number and db name with : `select oid,datname from pg_database where oid=18595;`
- Then in database : `select table_name,pg_relation_size(quote_ident(table_name)) from information_schema.tables where table_schema = 'public' order by 2;`

