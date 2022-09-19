---
title: "Installation"
description: Installation notes of eventline.adyxax.org on FreeBSD
tags:
- Eventline
- FreeBSD
- PostgreSQL
---

## Introduction

Please refer to [the official website](https://www.exograd.com/doc/eventline/handbook.html#_deployment_and_configuration) documentation for an up to date installation guide. This page only lists what I had to do at the time to setup eventline and adapt it to my particular setup.

## Preparing the postgresql database

A Postgresql database version 14 or above is the only dependency, let's install it:
```sh
pkg install postgresql14-server postgresql14-contrib
/usr/local/etc/rc.d/postgresql enable
/usr/local/etc/rc.d/postgresql initdb
/usr/local/etc/rc.d/postgresql start
```

Now let's provision a database:
```sh
su - postgres
createuser -W eventline
createdb -O eventline eventline
```

Connect to the database and activate the pgcryto extension:
```sql
psql -U eventline -W eventline
CREATE EXTENSION pgcrypto;
```

## Eventline

Exograd (the company behind eventline) maintains a FreeBSD repository, let's use it:
```sh
curl -sSfL -o /usr/local/etc/pkg/repos/exograd-public.conf \
     https://pkg.exograd.com/public/freebsd/exograd.conf
pkg update
pkg install eventline
```

Edit the `/usr/local/etc/eventline/eventline.yaml` configuration file:
```yaml
data_directory: "/usr/local/share/eventline"

api_http_server:
  address: "localhost:8085"

web_http_server:
  address: "localhost:8087"

web_http_server_uri: "http://localhost:8087"

pg:
  uri:
    "postgres://eventline:XXXXXXXX@localhost:5432/eventline"

# You need to generate a random encryption, for example using OpenSSL:
# openssl rand -base64 32
encryption_key: "YYYYYYYY"
```

Now start eventline with:
```sh
service eventline enable
service eventline start
```

## DNS record

Since all configuration regarding this application is in terraform, so is the dns:
```hcl
resource "cloudflare_record" "eventline-cname" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "eventline"
  value   = "10.1.2.5"
  type    = "A"
  proxied = false
}
```

This IP is the wireguard endpoint on the server hosting eventline. Having this hostname is important for the ssl certificate validation, otherwise firefox will complain!

## Nginx configuration for the webui

This nginx configuration listens on a wireguard interface:
```cfg
server {
        listen  10.1.2.5:80;
        server_name  eventline.adyxax.org;
        location / {
                return 308 https://$server_name$request_uri;
        }
}
# webui
server {
        listen  10.1.2.5:443 ssl;
        server_name  eventline.adyxax.org;

        location / {
                proxy_pass  http://127.0.0.1:8087;
                include headers_secure.conf;
        }
        ssl_certificate      adyxax.org.fullchain;
        ssl_certificate_key  adyxax.org.key;
}
# api-server
server {
        listen  10.1.2.5:8085 ssl;
        server_name  eventline.adyxax.org;

        location / {
                proxy_pass  http://127.0.0.1:8085;
                include headers_secure.conf;
        }
        ssl_certificate      adyxax.org.fullchain;
        ssl_certificate_key  adyxax.org.key;
}
```

## Admin account's password

Go to the domain you configured (https://eventline.adyxax.org/ for me) and login to your new eventline with username `admin` and password `admin`. Then go to `Account` and click `Change password`.
