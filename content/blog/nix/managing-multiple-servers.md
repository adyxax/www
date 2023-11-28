---
title: Managing multiple nixos hosts, remotely
description: How I manage my nixos servers
date: 2023-11-28
tags:
- nix
---

## Introduction

There seems to be almost too many tools to manage nix configurations with too many different approaches, each with their quirks and learning curve. Googling this issue was more troubling than it should be!

Therefore I tried to keep things simple and converged on a code organization that I find flexible enough for my current nixos needs without anything more than the standard nix tools.

## Repository layout

Here are the directories inside my nixos repository:
```
├── apps
│   ├── eventline
│   ├── files
│   ├── gotosocial
│   ├── miniflux
│   ├── privatebin
│   └── vaultwarden
├── hosts
│   ├── dalinar.adyxax.org
│   ├── lumapps-jde.adyxax.org
│   └── myth.adyxax.org
└── lib
    └── common
```

### apps

The `apps` directory contains files and configurations about each application I manage. Here is what an app folder looks like:
```
└── apps
    └── eventline
        ├── app.nix
        ├── borg-db.key
        ├── borg-db.key.pub
        ├── borg.nix
        ├── eventline-entrypoint
        └── eventline.yaml
```

Each of the app directories has an `app.nix` file detailing the nix configuration to deploy the app that will be included by the host running it, and a `borg.nix` with the configurations for the host that will be the borg backups target. In my setup each app has its own set of ssh keys (which are encrypted with `git-crypt`) for its borg jobs.

The remaining files are specific to the app. In this example there is a configuration file and a custom entrypoint for a container image.

### hosts

The hosts directory contains the specific configurations and files for each host running nixos. Here is what it looks like:
```
hosts/dalinar.adyxax.org/
├── configuration.nix
├── hardware-configuration.nix
└── wg0.key
```

The `confiuration.nix` currently looks like:
```nix
{ config, pkgs, ... }:
{
	imports = [
		./hardware-configuration.nix
		../../apps/eventline/app.nix
		../../apps/gotosocial/app.nix
		../../apps/ngircd.nix
		../../apps/privatebin/app.nix
		../../apps/teamspeak.nix
		../../lib/boot-uefi.nix
		../../lib/common.nix
	];
	environment.etc."wireguard/wg0.key".source = ./wg0.key;
	networking = {
		hostName = "dalinar";
		wireguard.interfaces."wg0" = {
			ips = [ "10.1.2.11/32" ];
			listenPort = 342;
			peers = [
				{	publicKey = "7mij2whbm0qMx/D12zdMS5i9lt3ZSI3quNomTI+BSgk=";
					allowedIPs = [ "10.1.2.14/32" ];
					endpoint = "lumapps-jde.adyxax.org:342"; }
			];
		};
	};
	systemd.network.networks.wan = {
		address = [ "2603:c022:c002:8500:e2a4:f02e:43b0:c1d8/128" ];
		matchConfig.Name = "eth0";
		networkConfig = { DHCP = "ipv4"; IPv6AcceptRA = true; };
	};
}
```

The `hardware-configuration.nix` is taken directly from the host machine after its installation.

The content of `wg0.key` is encrypted with `git-crypt` too and generated with:
```sh
wg genkey
```

### lib

The contents of the `lib` directory are used either directly from the hosts configurations, or from the apps configurations:
```
lib
├── boot-bios.nix
├── boot-uefi.nix
├── common
│   ├── borg-client.nix
│   ├── check-mk-agent.nix
│   ├── dns.nix
│   ├── mosh.nix
│   ├── network.nix
│   ├── nix.nix
│   ├── openssh.nix
│   ├── tmux.conf
│   ├── tmux.nix
│   └── wireguard.nix
├── common.nix
├── julien.nix
├── luks.nix
├── nginx.nix
└── postgresql.nix
```

All the files in `lib/common/` are included in `lib/common.nix`. These are split in self contained logical parts.

## Deploying to a remote host

I use the following `GNUmakefile` to deploy from my workstation or from my eventline server to my hosts:
```make
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

##### TASKS ####################################################################
.PHONY: run
run: mandatory-host-param ## make  run  host=<hostname>
	nixos-rebuild switch --target-host root@$(host) -I nixos-config=hosts/$(host)/configuration.nix

.PHONY: update
update: ## make  update
	nix-channel --update

##### UTILS ####################################################################
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: mandatory-host-param
mandatory-host-param:
ifndef host
	@echo "Error: host parameter is not set"; exit 1
else
ifeq ($(wildcard hosts/$(host)), )
	@echo "Error: host has no configuration in ./hosts/$(host)"; exit 1
endif
endif
```

This way I can `make run host=dalinar.adyxax.org` to build locally dalinar's configuration and deploy it remotely.

## Conclusion

I am quite happy with the simplicity of this system for now. Everything works smoothly and tinkering with the configurations does not involve any magic.

The one thing I really want to improve is the wireguard peers management which is a lot more involved than it needs to be. I will also explore using custom variables in order to simplify the hosts configurations.

In the next articles I will detail the code behind some of these apps and lib files.
