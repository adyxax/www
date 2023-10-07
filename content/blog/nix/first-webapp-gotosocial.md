---
title: Deploying a web application to nixos
description: A full example with my gotosocial instance
date: 2023-10-06
tags:
- nix
---

## Introduction

Gotosocial is a service that was running on one of my FreeBSD servers. Being a simple web application it is a good candidate to showcase what I like most about nixos and its declarative configurations!

## A bit about the nix language

I recommend you read [the official documentation](https://nixos.wiki/wiki/Overview_of_the_Nix_Language), but here is the minimal to get you started:
- every statement ends with a semicolon.
- The basic block structures are in fact Sets, meaning lists of key-value pairs where the keys are unique.
- The `{...}: { }` that structure the whole file is a module definition. In the first curly braces are arguments.
- The `let ...; in { }` construct is a way to define local variables for usage in the block following the `in`.
- You can write strings with double quotes or double single quotes. This makes it so that you almost never need to escape characters! The double single quotes also allow to write multi line strings that will smartly strip the starting white spaces.
- file system paths are not strings!
- list elements are separated by white spaces.
- You can merge the keys in two sets with `//`, often used in conjunction with `let` local variables.
- imports work by merging sets and appending lists.

Statements can be grouped but nothing is mandatory. For example the following are completely equivalent:
```nix
environment = {
	etc."gotosocial.yaml" = {
		mode = "0444";
		source = ./gotosocial.yaml;
	};
	systemPackages = [ pkgs.sqlite ];
};
```

```nix
environment.etc."gotosocial.yaml" = {
	mode = "0444";
	source = ./gotosocial.yaml;
};
environment.systemPackages = [ pkgs.sqlite ];
```

```nix
environment.etc."gotosocial.yaml".mode = "0444";
environment.etc."gotosocial.yaml".source = ./gotosocial.yaml;
environment.systemPackages = [ pkgs.sqlite ];
```

## Configuration

The following configuration does in order:
- Imports the Nginx.nix module defined in the next section.
- Deploys Gotosocial's YAML configuration file.
- Installs `sqlite`, necessary for our database backup preHook.
- Defines two Borg backup jobs: one for the SQLite database and one for the local storage.
- Configures an Nginx virtual host.
- Deploys the Gotosocial container.

```nix
{ config, pkgs, ... }:
{
	imports = [
	  ../lib/nginx.nix
	];
	environment = {
		etc."gotosocial.yaml" = {
			mode = "0444";
			source = ./gotosocial.yaml;
		};
		systemPackages = [ pkgs.sqlite ];
	};
	services = {
		borgbackup.jobs = let defaults = {
			compression = "auto,zstd";
			encryption.mode = "none";
			environment.BORG_RSH = "ssh -i /etc/borg.key";
			prune.keep = {
				daily = 14;
				weekly = 4;
				monthly = 3;
			};
			repo = "ssh://borg@kaladin.adyxax.org/srv/borg/dalinar.adyxax.org";
			startAt = "daily";
		}; in {
			"gotosocial-db" = defaults // {
				paths = "/tmp/gotosocial-sqlite.db";
				postHook = "rm -f /tmp/gotosocial-sqlite.db";
				preHook = ''
					rm -f /tmp/gotosocial-sqlite.db
					echo 'VACUUM INTO "/tmp/gotosocial-sqlite.db"' | \
					/run/current-system/sw/bin/sqlite3 /srv/gotosocial/sqlite.db
				'';
			};
			"gotosocial-storage" = defaults // { paths = "/srv/gotosocial/storage"; };
		};
		nginx.virtualHosts."fedi.adyxax.org" = {
			forceSSL = true;
			locations = {
				"/" = {
					proxyPass = "http://127.0.0.1:8082";
					proxyWebsockets = true;
				};
			};
			sslCertificate = "/etc/nginx/adyxax.org.crt";
			sslCertificateKey = "/etc/nginx/adyxax.org.key";
		};
	};
	virtualisation.oci-containers.containers.gotosocial = {
		cmd = [ "--config-path" "/gotosocial.yaml" ];
		image = "superseriousbusiness/gotosocial:0.11.1";
		ports = ["127.0.0.1:8082:8080"];
		volumes = [
			"/etc/gotosocial.yaml:/gotosocial.yaml:ro"
			"/srv/gotosocial/:/gotosocial/storage/"
		];
	};
}
```

## Nginx

I will go into details in a next article about imports and how I organize my configurations, just know that in this case imports work intuitively. Here is the `lib/nginx.nix` file defining common configuration for Nginx:
```nix
{ config, pkgs, ... }:
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

## Deploying

Being an existing service for me, I transferred gotosocial's storage data and database using rsync. With that done, bringing the service back up was only a matter of migrating the DNS and running the now familiar:
```sh
nixos-rebuild  switch
```

## Conclusion

I hope you find this way of declaratively configuring a whole operating system as elegant as I do. The nix configuration language is a bit rough, but I find it is not so hard to wrap your head around the basics. When it all clicks it is nice to know that you can reproduce this deployment anywhere just from this configuration!
