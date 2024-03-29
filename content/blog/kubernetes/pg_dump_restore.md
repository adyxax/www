---
title: "Dump and restore a postgresql database on kubernetes"
date: 2020-06-25
description: How to dump and restore a postgresql database running on kubernetes
tags:
  - k3s
  - kubernetes
  - PostgreSQL
---

## Dumping
Assuming we are working with a postgresql statefulset, our namespace is named `miniflux` and our master pod is named `db-postgresql-0`, trying to
dump a database named `miniflux`:
```sh
export POSTGRES_PASSWORD=$(kubectl get secret --namespace miniflux db-postgresql \
  -o jsonpath="{.data.postgresql-password}" | base64 --decode)
kubectl run db-postgresql-client --rm --tty -i --restart='Never' --namespace miniflux \
  --image docker.io/bitnami/postgresql:11.8.0-debian-10-r19 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
  --command -- pg_dump --host db-postgresql -U postgres -d miniflux > miniflux.sql-2020062501
```

## Restoring

Assuming we are working with a postgresql statefulset, our namespace is named `miniflux` and our master pod is named `db-postgresql-0`, trying to
restore a database named `miniflux`:
```sh
kubectl -n miniflux cp miniflux.sql-2020062501 db-postgresql-0:/tmp/miniflux.sql
kubectl -n miniflux exec -ti db-postgresql-0 -- psql -U postgres -d miniflux
miniflux=# \i /tmp/miniflux.sql
kubectl -n miniflux exec -ti db-postgresql-0 -- rm /tmp/miniflux.sql
```
