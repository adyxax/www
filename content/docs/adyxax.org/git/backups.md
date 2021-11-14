---
title: "Backups"
description: Backups of git.adyxax.org
---

## Documentation

Backups are configured with borg on `dalinar.adyxax.org` to `yen.adyxax.org`.

There are two jobs :
- a filesystem backup of `/srv/gitea-data`
- a `VACUUM INTO` backup job of gitea's SQLite database
