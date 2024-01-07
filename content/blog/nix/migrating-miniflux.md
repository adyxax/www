---
title: Migrating miniflux to nixos
description: How I migrated my miniflux installation to nixos
date: 2024-01-07
tags:
- miniflux
- nix
---

## Introduction

I am migrating several services from a k3s kubernetes cluster to a nixos server. Here is how I performed the operation with my [miniflux rss reader](https://miniflux.app/).

## Miniflux with nixos

Miniflux is packaged on nixos, but I am used to the container image so I am sticking with it for now.

Here is the module I wrote to deploy a miniflux container, configure postgresql and borg backups:
```nix
{ config, lib, pkgs, ... }:
{
	imports = [
	  ../../lib/borg-client.nix
	  ../../lib/postgresql.nix
	  ../../lib/nginx.nix
	];
	environment.etc."borg-miniflux-db.key" = {
		mode = "0400";
		source = ./borg-db.key;
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
			"miniflux-db" = defaults // {
				environment.BORG_RSH = "ssh -i /etc/borg-miniflux-db.key";
				paths = "/tmp/miniflux.sql";
				postHook = "rm -f /tmp/miniflux.sql";
				preHook = ''rm -f /tmp/miniflux.sql; /run/current-system/sw/bin/pg_dump -h localhost -U miniflux -d miniflux > /tmp/miniflux.sql'';
				repo = "ssh://borg@gcp.adyxax.org/srv/borg/miniflux-db";
			};
		};
		nginx.virtualHosts."miniflux.adyxax.org" = {
			forceSSL = true;
			locations = {
			  "/" = {
			    proxyPass = "http://127.0.0.1:8084";
			  };
			};
			sslCertificate = "/etc/nginx/adyxax.org.crt";
			sslCertificateKey = "/etc/nginx/adyxax.org.key";
		};
		postgresql = {
			ensureUsers = [{
				name = "miniflux";
				ensurePermissions = { "DATABASE \"miniflux\"" = "ALL PRIVILEGES"; };
			}];
			ensureDatabases = ["miniflux"];
		};
	};
	virtualisation.oci-containers.containers = {
		miniflux = {
			environment = {
				ADMIN_PASSWORD = lib.removeSuffix "\n" (builtins.readFile ./admin-password.key);
				ADMIN_USERNAME = "admin";
				DATABASE_URL = "postgres://miniflux:" + (lib.removeSuffix "\n" (builtins.readFile ./database-password.key)) + "@10.88.0.1/miniflux?sslmode=disable";
				RUN_MIGRATIONS = "1";
			};
			image = "miniflux/miniflux:2.0.50";
			ports = ["127.0.0.1:8084:8080"];
		};
	};
}
```

## Dependencies

The dependencies are mostly the same as in [my article about vaultwarden migration]({{< ref "migrating-vaultwarden.md" >}}#dependencies).

## Migration process

The first step is obviously to deploy this new configuration to the server, then I need to login and manually restore the backups.
```sh
make run host=dalinar.adyxax.org
```

The container will be failing because no password is set on the database user yet, so I stop it:
```sh
systemctl stop podman-miniflux
```

There is only one backup job for miniflux and it holds a dump of the database:
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

Afterwards I clean up the database dump and restart miniflux:
```sh
rm -rf tmp/
systemctl start podman-miniflux
```

To wrap this up I migrate the DNS records to the new host, update my monitoring system and clean up the namespace on the k3s server.

## Conclusion

I did all this in november, I have quite the backlog of articles to write!
