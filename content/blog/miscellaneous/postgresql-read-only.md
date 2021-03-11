---
title: "Grant postgresql read only access"
linkTitle: "Grant postgresql read only access"
date: 2015-11-24
description: >
  Grant postgresql read only access
---

{{< highlight sh >}}
GRANT CONNECT ON DATABASE "db" TO "user";
\c db
GRANT USAGE ON SCHEMA public TO "user";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO "user";
{{< /highlight >}}

