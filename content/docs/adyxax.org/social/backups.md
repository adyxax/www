---
title: "Backups"
description: Backups of social.adyxax.org
---

## Documentation

Backups are configured with borg on `myth.adyxax.org` to `yen.adyxax.org`.

There is only on jobs :
```yaml
- name: ktistec-db
  path: "/tmp/ktistec.db"
  pre_command: "echo \"VACUUM INTO '/tmp/ktistec.db'\"|sqlite3 /srv/ktistec-db/ktistec.db"
  post_command: "rm -f /tmp/ktistec.db"
```
