---
title: Migrating eventline to nixos
description: How I migrated my eventline installation to nixos
date: 2024-03-22
tags:
- eventline
- nix
---

## Introduction

I am migrating several services from a FreeBSD server to a nixos server. Here is how I performed the operation for [eventline](https://www.exograd.com/products/eventline/).

## Eventline on nixos

Eventline is not packaged on nixos, so that might be a good project to try and tackle in the near future. In the meantime I used the container image.

Here is the module I wrote to deploy an eventline container, configure postgresql and borg backups:
```nix
{ config, lib, pkgs, ... }:
{
    imports = [
      ../../lib/postgresql.nix
    ];
    environment.etc = {
        "borg-eventline-db.key" = {
            mode = "0400";
            source = ./borg-db.key;
        };
        "eventline.yaml" = {
            mode = "0400";
            source = ./eventline.yaml;
            uid = 1000;
        };
        "eventline-entrypoint" = {
            mode = "0500";
            source = ./eventline-entrypoint;
            uid = 1000;
        };
    };
    services = {
        borgbackup.jobs = let defaults = {
            compression = "auto,zstd";
            doInit = true;
            encryption.mode = "none";
            prune.keep = {
                daily = 14;
                weekly = 4;
                monthly = 3;
            };
            startAt = "daily";
        }; in {
            "eventline-db" = defaults // {
                environment.BORG_RSH = "ssh -i /etc/borg-eventline-db.key";
                paths = "/tmp/eventline.sql";
                postHook = "rm -f /tmp/eventline.sql";
                preHook = ''rm -f /tmp/eventline.sql; /run/current-system/sw/bin/pg_dump -h localhost -U eventline -d eventline > /tmp/eventline.sql'';
                repo = "ssh://borg@gcp.adyxax.org/srv/borg/eventline-db";
            };
        };
        nginx.virtualHosts = let
            headersSecure = ''
                # A+ on https://securityheaders.io/
                add_header X-Frame-Options deny;
                add_header X-XSS-Protection "1; mode=block";
                add_header X-Content-Type-Options nosniff;
                add_header Referrer-Policy strict-origin;
                add_header Cache-Control no-transform;
                add_header Content-Security-Policy "script-src 'self'";
                add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()";
                # 6 months HSTS pinning
                add_header Strict-Transport-Security max-age=16000000;
            '';
            headersStatic = headersSecure + ''
                add_header Cache-Control "public, max-age=31536000, immutable";
            '';
        in {
            "eventline.adyxax.org" = {
                forceSSL = true;
                locations = {
                    "/" = {
                        extraConfig = headersSecure;
                        proxyPass = "http://127.0.0.1:8087";
                    };
                };
                sslCertificate = "/etc/nginx/adyxax.org.crt";
                sslCertificateKey = "/etc/nginx/adyxax.org.key";
            };
            "eventline-api.adyxax.org" = {
                locations = {
                    "/" = {
                        extraConfig = headersSecure;
                        proxyPass = "http://127.0.0.1:8085";
                    };
                };
                onlySSL = true;
                sslCertificate = "/etc/nginx/adyxax.org.crt";
                sslCertificateKey = "/etc/nginx/adyxax.org.key";
            };
        };
        postgresql = {
            ensureDatabases = ["eventline"];
            ensureUsers = [{
                name = "eventline";
                ensureDBOwnership = true;
            }];
        };
    };
    virtualisation.oci-containers.containers = {
        eventline = {
            image = "exograd/eventline:1.1.0";
            ports = [
                "127.0.0.1:8085:8085" # api
                "127.0.0.1:8087:8087" # web
            ];
            user = "root:root";
            volumes = [
                "/etc/eventline.yaml:/etc/eventline/eventline.yaml:ro"
                "/etc/eventline-entrypoint:/usr/bin/entrypoint:ro"
            ];
        };
    };
}
```

## Dependencies

The dependencies are mostly the same as in [my article about vaultwarden migration]({{< ref "migrating-vaultwarden.md" >}}#dependencies). One key difference is that there are two nginx virtual hosts and a bunch of files I need for eventline.

## Migration process

The first step is obviously to deploy this new configuration to the server, then I need to login and manually restore the backups.
```sh
make run host=dalinar.adyxax.org
```

The container will be failing because no password is set on the database user yet, so I stop it:
```sh
systemctl stop podman-eventline
```

There is only one backup job for eventline and it holds a dump of the database:
```sh
export BORG_RSH="ssh -i /etc/borg-eventline-db.key"
borg list ssh://borg@gcp.adyxax.org/srv/borg/eventline-db
borg extract ssh://borg@gcp.adyxax.org/srv/borg/eventline-db::dalinar-eventline-db-2023-11-20T00:00:01
psql -h localhost -U postgres -d eventline
```

Restoring the data itself is done with the psql shell:
```sql
ALTER USER eventline WITH PASSWORD 'XXXXXX';
\i tmp/eventline.sql
```

Afterwards I clean up the database dump and restart eventline:
```sh
rm -rf tmp/
systemctl start podman-eventline
```

To wrap this up I migrate the DNS records to the new host, update my monitoring system and clean up the jail on the FreeBSD server.

## Conclusion

I did all this in november, I still have quite the backlog of articles to write about nix!
