---
title: "Backups"
description: Backups of social.adyxax.org
---

## Documentation

Backups are configured with borg on `lore.adyxax.org` to `yen.adyxax.org`.

There are two jobs:
```yaml
- name: gotosocial-data
  path: "/jails/fedi/root/home/fedi/storage"
- name: gotosocial-db
  path: "/tmp/gotosocial.db"
  pre_command: "echo \"VACUUM INTO '/tmp/gotosocial.db'\"|sqlite3 /jails/fedi/root/home/fedi/sqlite.db"
  post_command: "rm -f /tmp/gotosocial.db"
```
