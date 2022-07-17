---
title: "gitolite"
description: Installation notes of gitolite
---

## Introduction

This article details how I installed and configured gitolite on FreeBSD, with ansible.

## Installation

gitolite can be bootstrapped with the following :
```yaml
- name: Install common freebsd packages
  package:
    name:
      - gitolite
```

I create a system group and a system user:
```yaml
- name: Create git group on server
  group:
    name: git
    system: yes
- name: Create git user on server
  user:
    name: git
    group: git
    shell: /bin/sh
    home: /srv/git
    createhome: yes
    system: yes
    password: '*'
```

Repositories will be kept under `/srv/git`. This password is a special value for the user module that specifies a disabled password.

## Initial setup

For this step you need to upload your public ssh key to the server and put it in the `/srv/git` directory. The following will then create a `gitolite-admin` repository and configure your public ssh key so that you can access it:
```sh
su - git
gitolite setup -pk id_ed25519.pub
```

You should then be able to clone the `gitolite-admin` repository on your workstation:
```sh
git clone git@git.adyxax.org:gitolite-admin
```

## Configuration

In order to customize the cgit frontend, I needed to allow some git configuration keys in `/srv/git/.gitolite.rc`. I manage the whole file with ansible, but here is the relevant line near the top of the file:
```perl
GIT_CONFIG_KEYS => 'cgit.desc cgit.extra-head-content cgit.homepage cgit.hide cgit.ignore cgit.owner cgit.section',
```

These keys allow me to specify repositories like this:
```perl
repo adyxax/bareos-zabbix-check
        RW+ = adyxax
        config cgit.desc = A Zabbix check for bareos backups
        config cgit.extra-head-content=<meta name="go-import" content="git.adyxax.org/adyxax/bareos-zabbix-check git https://git.adyxax.org/adyxax/bareos-zabbix-check">
        config cgit.owner = Julien Dessaux
        config cgit.section = Active
```

The `cgit.extra-head-content` is vital for `go get` and `go install` to work properly and took me some google-fu to figure out.
