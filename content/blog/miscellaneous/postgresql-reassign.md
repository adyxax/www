---
title: "Change owner on a postgresql database and all tables"
date: 2012-04-20
description: How to change owner on a postgresql database and all tables
tags:
  - PostgreSQL
---

## The solution

Here is the sequence of commande that will change the owner of all objects in a database from a user named "support" to another named "test-support":
{{< highlight sh >}}
ALTER DATABASE name OWNER TO new_owner
for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" YOUR_DB` ; do psql -c "alter table $tbl owner to NEW_OWNER" YOUR_DB ; done
for tbl in `psql -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'public';" YOUR_DB` ; do  psql -c "alter table $tbl owner to NEW_OWNER" YOUR_DB ; done
for tbl in `psql -qAt -c "select table_name from information_schema.views where table_schema = 'public';" YOUR_DB` ; do  psql -c "alter table $tbl owner to NEW_OWNER" YOUR_DB ; done
{{< /highlight >}}

{{< highlight sh >}}
reassign owned by "support" to "test-support";
{{< /highlight >}}
