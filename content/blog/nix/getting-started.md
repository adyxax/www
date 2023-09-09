---
title: Getting started with nix
description: Using nix on any linux distribution
date: 2023-09-09
tags:
- nix
---

## Introduction

I have been using nix for a few months now. It is a modern package manager that focuses on reproducible builds and was a first step before using nixos, a linux distribution based around nix and its capabilities that I find intriguing. Being able to have a fully reproducible system from a declarative configuration is something I find enticing.

## Getting started

You can get started using nix on any linux distribution, even on macos or windows! You do not need to reinstall anything or boot another operating system: you can install nix and start taking advantage of it anytime anywhere.

[The official documentation](https://nixos.org/download) (which you should refer to) mentions two alternatives: one which runs a daemon to allow for multiple users to use nix on the same system, and a simpler one without a running daemon which I chose to follow.

I recommend you audit the installation script, it is always a good idea to do so (and in this case it is quite simple to read what it does), but here are the three installation steps:
```sh
doas mkdir /nix
doas chown adyxax /nix
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

If this completes without error, you now have nix installed and just need to activate it in your shell with:
```sh
source ~/.nix-profile/etc/profile.d/nix.sh
```

To make this persistent add it where relevant for your shell and distribution, it could be in `~/.bashrc`, `~/.profile`, `~/.zshrc`, etc:
```sh
if [ -e "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]; then
	source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
fi
```

## Using nix

### Nix channels

By default, your nix installation should use the unstable profile. That just means bleeding edge packages, but I like to be explicit when using bleeding edge stuff therefore I did:
```sh
nix-channel --remove nixpkgs
nix-channel --add https://nixos.org/channels/nixos-23.05  nixpkgs
nix-channel --add https://nixos.org/channels/nixos-unstable  nixpkgs-unstable
nix-channel --update
```

23.05 is the current stable release channel at the time of this writing. Please check the current one at the time of your reading and use that.

Be careful not to change this version number mindlessly as it can affect anything stateful you install with nix. The most common problem you will encounter is about file locations that change with major database versions (for example postgresql14 and 15). Changing this 23.05 version would not migrate your data, so be careful that you can migrate or have migrated all the state from your nix packages which is affected by this kind of version changes. I will write a blog article about this when it happens to me.

### Searching packages

The easiest and fastest way is through nixos's website: https://search.nixos.org/packages?channel=23.05

If you want to do it from the cli beware that it is a bit slow, particularly on the first run (maybe it is building some cache):
```sh
$ nix-env -qaP firefox   # short for: nix-env --query --available --attr-path firefox
nixpkgs.firefox-esr-102               firefox-102.15.0esr
nixpkgs-unstable.firefox-esr-102      firefox-102.15.0esr
nixpkgs.firefox-esr                   firefox-115.2.0esr
nixpkgs.firefox-esr-wayland           firefox-115.2.0esr
nixpkgs-unstable.firefox-esr          firefox-115.2.0esr
nixpkgs-unstable.firefox-esr-wayland  firefox-115.2.0esr
nixpkgs.firefox                       firefox-117.0
nixpkgs.firefox-wayland               firefox-117.0
nixpkgs-unstable.firefox              firefox-117.0
nixpkgs-unstable.firefox-mobile       firefox-117.0
nixpkgs-unstable.firefox-wayland      firefox-117.0
nixpkgs.firefox-beta                  firefox-117.0b9
nixpkgs.firefox-devedition            firefox-117.0b9
nixpkgs-unstable.firefox-beta         firefox-117.0b9
nixpkgs-unstable.firefox-devedition   firefox-117.0b9
```

As you can see, the nixpkgs stable channels does not lag behind unstable for most day to day things you would need updated, but it will for more system things or experimental software.
```sh
$ nix-env -qaP gotosocial
nixpkgs-unstable.gotosocial  gotosocial-0.11.0
```

### Installing packages

```sh
nix-env -iA nixpkgs.emacs29   # short for: nix-env --install --attr nixpkgs.emacs29
```

### Listing installed packages

```sh
$ nix-env -qs   # short for: nix-env --query --status
IPS  emacs-29.1
```

Note that the installed package name changed completely and no longer reference nixpkgs or nixpkgs-unstable! That comes from the notion of nix derivations which we will not get into in this article.

### Upgrading packages

```sh
nix-channel --update
nix-env --upgrade
```

### Uninstalling packages

```sh
nix-env --uninstall emacs-29.1
```

## Maintaining nix itself

### Updating nix

```sh
nix-channel --update
nix-env --install --attr nixpkgs.nix nixpkgs.cacert
```

### Uninstalling nix

If at some point you want to stop using nix and uninstall it, simply run:
```sh
rm -rf "${HOME}/.nix-profile"
doas rm -rf /nix
```

## Conclusion

This article is a first overview of nix that can get you started, we did not get into the best parts yet: profile management, rolling back to a previous packages state, packaging software, building container images and of course nixos itself. So much material for future articles!

I have been a happy Gentoo user for close to twenty years now and do not plan to switch anytime soon for many reasons, but it is nice to have another packages repository to play with.
