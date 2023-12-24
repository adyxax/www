---
title: Migrating vaultwarden to nixos
description: How I migrated my vaultwarden installation to nixos
date: 2023-12-20
tags:
- nix
- vaultwarden
---

## Introduction

I am migrating several services from a k3s kubernetes cluster to a nixos server. Here is how I performed the operation with my [vaultwarden](https://github.com/dani-garcia/vaultwarden) password manager.

## Vaultwarden with nixos

Vaultwarden is packaged on nixos, but I am used to the hosting the container image and upgrading it at my own pace so I am sticking with it for now.

Here is the module I wrote to deploy a vaultwarden container, configure postgresql and borg backups in `apps/vaultwarden/app.nix`:
```nix
{ config, lib, pkgs, ... }:
{
	imports = [
	  ../../lib/nginx.nix
	  ../../lib/postgresql.nix
	];
	environment.etc = {
		"borg-vaultwarden-db.key" = {
			mode = "0400";
			source = ./borg-db.key;
		};
		"borg-vaultwarden-storage.key" = {
			mode = "0400";
			source = ./borg-storage.key;
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
			"vaultwarden-db" = defaults // {
				environment.BORG_RSH = "ssh -i /etc/borg-vaultwarden-db.key";
				paths = "/tmp/vaultwarden.sql";
				postHook = "rm -f /tmp/vaultwarden.sql";
				preHook = ''rm -f /tmp/vaultwarden.sql; /run/current-system/sw/bin/pg_dump -h localhost -U vaultwarden -d vaultwarden > /tmp/vaultwarden.sql'';
				repo = "ssh://borg@gcp.adyxax.org/srv/borg/vaultwarden-db";
			};
			"vaultwarden-storage" = defaults // {
				environment.BORG_RSH = "ssh -i /etc/borg-vaultwarden-storage.key";
				paths = "/srv/vaultwarden";
				repo = "ssh://borg@gcp.adyxax.org/srv/borg/vaultwarden-storage";
			};
		};
		nginx.virtualHosts = let commons = {
			forceSSL = true;
			locations = {
			  "/" = {
			    proxyPass = "http://127.0.0.1:8083";
			  };
			};
		}; in {
			"pass.adyxax.org" = commons // {
				sslCertificate = "/etc/nginx/adyxax.org.crt";
				sslCertificateKey = "/etc/nginx/adyxax.org.key";
			};
		};
		postgresql = {
			ensureUsers = [{
				name = "vaultwarden";
				ensureDBOwnership = true;
			}];
			ensureDatabases = ["vaultwarden"];
		};
	};
	virtualisation.oci-containers.containers = {
		vaultwarden = {
			environment = {
				ADMIN_TOKEN = builtins.readFile ./argon-token.key;
				DATABASE_MAX_CONNS = "2";
				DATABASE_URL = "postgres://vaultwarden:" + (lib.removeSuffix "\n" (builtins.readFile ./database-password.key)) + "@10.88.0.1/vaultwarden?sslmode=disable";
			};
			image = "vaultwarden/server:1.30.1";
			ports = ["127.0.0.1:8083:80"];
			volumes = [ "/srv/vaultwarden/:/data" ];
		};
	};
}
```

## Dependencies

### Borg

Borg needs to be running on another server with the following configuration stored in my `apps/vaultwarden/borg.nix` file:
```nix
{ config, pkgs, ... }:
{
        imports = [
          ../../lib/borg.nix
        ];
        users.users.borg.openssh.authorizedKeys.keys = [
                ("command=\"borg serve --restrict-to-path /srv/borg/vaultwarden-db\",restrict " + (builtins.readFile ./borg-db.key.pub))
                ("command=\"borg serve --restrict-to-path /srv/borg/vaultwarden-storage\",restrict " + (builtins.readFile ./borg-storage.key.pub))
        ];
}
```

### PostgreSQL

My postgreSQL module defines the following global configuration:
```nix
{ config, lib, pkgs, ... }:
{
	networking.firewall.interfaces."podman0".allowedTCPPorts = [ 5432 ];
	services.postgresql = {
		enable = true;
		enableTCPIP = true;
		package = pkgs.postgresql_15;
		authentication = pkgs.lib.mkOverride 10 ''
			#type database  DBuser                 auth-method
			local all       all                    trust
			# podman
			host  all       all     10.88.0.0/16   scram-sha-256
		'';
	};
}
```

Since for now I am running nothing outside of containers on this server, I am trusting the unix socket connections. Depending on what you are doing you might want a stronger auth-method there.

### Nginx

My nginx module defines the following global configuration:
```nix
{ config, lib, pkgs, ... }:
{
	environment.etc = let permissions = { mode = "0400"; uid= config.ids.uids.nginx; }; in {
		"nginx/adyxax.org.crt" = permissions // { source = ../../01-legacy/adyxax.org.crt; };
		"nginx/adyxax.org.key" = permissions // { source = ../../01-legacy/adyxax.org.key; };
	};
	networking.firewall.allowedTCPPorts = [ 80 443 ];
	services.nginx = {
		clientMaxBodySize = "40M";
		enable = true;
		enableReload = true;
		recommendedGzipSettings = true;
		recommendedOptimisation = true;
		recommendedProxySettings = true;
	};
}
```

### Secrets

There are several secrets referenced in the configuration, these are all git-crypted files:
- argon-token.key
- borg-db.key
- borg-storage.key
- database-password.key

## Migration process

The first step is obviously to deploy this new configuration to the server, then I need to login and manually restore the backups.
```sh
make run host=myth.adyxax.org
```

The container will be failing because no password is set on the database user yet, so I stop it:
```sh
systemctl stop podman-vaultwarden
```

There are two backup jobs for vaultwarden: one for its storage and the second one for the database.
```sh
export BORG_RSH="ssh -i /etc/borg-vaultwarden-storage.key"
borg list ssh://borg@gcp.adyxax.org/srv/borg/vaultwarden-storage
borg extract ssh://borg@gcp.adyxax.org/srv/borg/vaultwarden-storage::dalinar-vaultwarden-storage-2023-11-19T00:00:01
mv srv/vaultwarden /srv/
```

```sh
export BORG_RSH="ssh -i /etc/borg-vaultwarden-db.key"
borg list ssh://borg@gcp.adyxax.org/srv/borg/vaultwarden-db
borg extract ssh://borg@gcp.adyxax.org/srv/borg/vaultwarden-db::dalinar-vaultwarden-db-2023-11-19T00:00:01
psql -h localhost -U postgres -d vaultwarden
```

Restoring the data itself is done with the psql shell:
```sql
ALTER USER vaultwarden WITH PASSWORD 'XXXXX';
\i tmp/vaultwarden.sql
```

Afterwards I clean up the database dump and restart vaultwarden:
```sh
rm -rf tmp/
systemctl start podman-vaultwarden
```

To wrap this up I migrate the DNS records to the new host, update my monitoring system and clean up the namespace on the k3s server.

## Conclusion

Automating things with nixos is satisfying, but it does not abstract all the sysadmin's work away.

I am not quite satisfied with my borg configuration entries. I should be able to write this more elegantly when I find the time, but it works.
