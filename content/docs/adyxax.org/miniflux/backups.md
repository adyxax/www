---
title: "Backups"
description: Backups of miniflux.adyxax.org
tags:
- UpdateNeeded
---

## Documentation

Backups are configured with borg on `myth.adyxax.org` and end up on `gcp.adyxax.org`.

There is only one jobs :
- a pg_dump of miniflux's postgresql database

## How to restore

The first step is to deploy miniflux to the destination server, then I need to login with ssh and manually restore the data.
```sh
make run host=myth.adyxax.org
```

The container will be failing because no password is set on the database user yet, so stop it:
```sh
systemctl stop podman-miniflux
```

There is only one backup job for miniflux. It contains a dump of the database:
```sh
export BORG_RSH="ssh -i /etc/borg-miniflux-db.key"
borg list ssh://borg@gcp.adyxax.org/srv/borg/miniflux-db
borg extract ssh://borg@gcp.adyxax.org/srv/borg/miniflux-db::dalinar-miniflux-db-2023-11-20T00:00:01
psql -h localhost -U postgres -d miniflux
```

Restoring the data itself is done with the psql shell:
```sql
ALTER USER miniflux WITH PASSWORD 'XXXXXX';
\i tmp/miniflux.sql
```

Afterwards clean up the database dump and restart miniflux:
```sh
rm -rf tmp/
systemctl start podman-miniflux
```

To wrap this up, migrate the DNS records to the new host and update the monitoring system.
