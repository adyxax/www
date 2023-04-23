---
title: "Grant PostgreSQL read only access"
date: 2015-11-24
description: How to grant read only access to a PostgreSQL user
tags:
  - PostgreSQL
---

## The solution

Here is the bare minimum a user need in order to have complete read only access on a postgresql database :
```sh
GRANT CONNECT ON DATABASE "db" TO "user";
\c db
GRANT USAGE ON SCHEMA public TO "user";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "user";
```
