---
title: "Backups"
description: Backups of pass.adyxax.org
tags:
- UpdateNeeded
---

## Documentation

Backups are configured with borg on `myth.adyxax.org` to `yen.adyxax.org`.

There are two jobs :
- a filesystem backup of `/srv/vaultwarden-data`
- a pg_dump of vaultwarden's postgresql database
