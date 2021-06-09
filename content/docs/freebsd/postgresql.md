---
title: Postgresql jail with bastille
description: How to install a PostgreSQL jail with bastille
---

## Jail initialization

The following creates a release jail :
```
bastille create postgresql 13.0-RELEASE 10.0.0.3/24
```

Use latest packages instead of quarterly (optional) :
```
echo 'mkdir -p /usr/local/etc/pkg/repos
      echo "FreeBSD: { enabled: no }" > /usr/local/etc/pkg/repos/FreeBSD.conf
      sed -e "s/^FreeBSD:/latest:/" -e "s/quarterly/latest/"  /etc/pkg/FreeBSD.conf > /etc/pkg/latest.conf' \
| bastille console postgresql
```

Postgresql needs us to allow system V IPC for the jail :
```
bastille config postgresql set allow.sysvipc=1
bastille restart postgresql
```

## Install PostgreSQL and initialize the database

Install PostgreSQL (version 13 at the time of this writing) :
```
pkg -j postgresql install -y postgresql13-server
```

If you need a character encoding other than UTF-8 now is the time to customize it, the post install message explains how. UTF-8 is the most compatible and usually what you want but it is also a variable byte length encoding therefore not optimal for all workloads. It can depend on your applications, for example bacula and bareos need SQL_ASCII.

It is also a good time to make Postgresql listen on the jail ip address :
```
echo "listen_addresses = '10.0.0.3'" \
    | bastille cmd postgresql tee -a /var/db/postgres/data13/postgresql.conf
```

I also like to use the modern scram-sha-256 authentication method instead of md5, just make sur your apps or libraries are recent enough to connect to it :
```
echo "password_encryption = 'scram-sha-256'" \
    | bastille cmd postgresql tee -a /var/db/postgres/data13/postgresql.conf
```

When ready, proceed to init the database :
```
bastille service postgresql postgresql enable
bastille service postgresql postgresql initdb
bastille service postgresql postgresql start
```

## Provision a user and database

Let's say we want to allow a gitea jail running from 10.0.0.4 to a gitea database using a gitea user :
```
echo "CREATE ROLE gitea WITH LOGIN PASSWORD 'secret';" \
    | bastille cmd postgresql su - postgres -c psql
echo "CREATE DATABASE gitea WITH OWNER gitea TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';" \
    | bastille cmd postgresql su - postgres -c psql
echo "host     gitea     gitea    10.0.0.4/32    scram-sha-256"
    | bastille cmd postgresql tee -a /var/db/postgres/data13/pg_hba.conf
bastille service postgresql postgresql reload
```
