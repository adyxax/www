---
title: 'Deploying a Forgejo runner with ansible'
description: 'Some ansible code and a golden rule'
date: '2025-04-08'
tags:
- 'ansible'
- 'Forgejo'
---

## Introduction

After [migrating my git.adyxax.org to Forgejo]({{< ref "forgejo.md" >}}) a few
weeks back, I started experimenting with their CI offering: Forgejo Actions. It
is mostly a clone of GitHub actions, which means it is a mixed bag.

I am still relying on [eventline](https://www.exograd.com/products/eventline)
for all the important stuff I manage, but I wanted to get the actions
integration for some simple and non consequential CI jobs.

## The good and the bad

The good part is obviously the tight integration with Forgejo's UI. Forgejo (or
gitea which Forgejo forked from) developers also made the great decision of
adding runners dedicated to individual users, which allows me to open my Forgejo
instance to other people without offering them access to a runner.

The bad part all has to do with trying to be a GitHub actions clone:
- The reliance on nodejs actions for everything.
- The non case sensitivity in weird places (the most damning example in my eyes
  being `if: ${{ github.ref == 'refs/heads/main' }}` which looks like an
  equality check, but it will match any case variation of `MaIn`).
- It is YAML soup, and workflow reuse is clunky at best.

## The golden rule

I find that the following golden rule applies to all CIs: avoid building any
actual logic into your workflows outside of the simple orchestration of the
tasks. [Here is an
example](https://git.adyxax.org/adyxax/www/src/branch/main/.forgejo/workflows/main.yaml)
workflow that illustrates this rule.

As you can see, I use simple (and often one liner) build, test or deploy
commands that call a Makefile to do the heavy lifting. This guarantees that I am
always able to build or deploy locally as well as debug more easily my
workflows.

## Making do without the runner containers

I greatly dislike the default Forgejo runner containers: They package everything
and the kitchen sink, which is necessary given how clunky the whole nodejs
ecosystem is (which the actions rely on).

Fortunately I can do without these runner containers. The documentation will
warn about its dangers and I caution you too if you plan to follow in my
footsteps: You need to manage the proper isolation yourself and take care of not
making a mess of the host operating system!

Managing the proper isolation is not hard: instead of letting Forgejo runner
spawn its own containers, I myself run it constrained inside either a container
or a jail.

Not making a mess of the host operating system requires discipline though
because the runner environment does not get cleaned on each run. Since I write
my workflows and actions myself and follow the previously mentioned golden rule,
with some discipline and experience I make it work.

## Ansible role

### Tasks

Here is an example `tasks.yaml` that deploys the Forgejo runner on a Debian
system. It does not configure the runner itself, that I do manually once after
the first deployment.

``` yaml
---
- name: 'Install forgejo-runner dependencies'
  package:
    name:
      - 'git-crypt'
      - 'hugo'
      - 'nodejs'

- name: 'Download forgejo runner {{ versions.forgejo_runner.tag }}'
  get_url:
    url: 'https://code.forgejo.org/forgejo/runner/releases/download/v{{ versions.forgejo_runner.tag }}/forgejo-runner-{{ versions.forgejo_runner.tag }}-linux-amd64'
    dest: '/usr/local/bin/forgejo-runner'
    mode: '0555'
  notify: 'restart forgejo runner'

- name: 'Create forgejo-runner group on server'
  group:
    name: 'forgejo-runner'
    system: 'yes'

- name: 'Create forgejo-runner user on server'
  user:
    name: 'forgejo-runner'
    group: 'forgejo-runner'
    shell: '/bin/sh'
    home: '/srv/forgejo-runner'
    createhome: 'yes'
    system: 'yes'
    password: '*'

- name: 'Deploy forgejo systemd service unit'
  copy:
    src: 'forgejo-runner.service'
    dest: '/etc/systemd/system/'
    owner: 'root'
    group: 'root'
    mode: '0440'
  notify: 'systemctl daemon-reload'

- name: 'Start forgejo-runner and activate it on boot'
  service:
    name: 'forgejo-runner'
    enabled: true
    state: 'started'
```

### Handlers

This role relies on two handlers:

``` yaml
---
- name: 'restart forgejo runner'
  service:
    name: 'forgejo-runner'
    state: 'restarted'

- name: 'systemctl daemon-reload'
  shell:
    cmd: 'systemctl daemon-reload'
```

### Files

Here is my `forgejo-runner.service` systemd unit file:

``` ini
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################
[Unit]
Description=Forgejo Runner
Documentation=https://forgejo.org/docs/latest/admin/actions/
After=network.target

[Service]
ExecStart=forgejo-runner daemon
ExecReload=/bin/kill -s HUP $MAINPID
User=forgejo-runner
WorkingDirectory=/srv/forgejo-runner
Restart=on-failure
TimeoutSec=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Manual runner registration

There is an offline registration mechanism, but I did not attempt to use it.
Since this is not an action I will redo often, I am content with running once:

``` shell
su - forgejo-runner
forgejo-runner register
               --instance https://git.adyxax.org \
               --labels self-hosted:host://-self-hosted \
               --name myth.adyxax.org \
               --token XXXXXXXXXXX \
               --no-interactive
exit
systemctl restart forgejo-runner
```

The registration token comes from my user settings page at
https://git.adyxax.org/user/settings/actions/runners/.

## Conclusion

It works well, for now I am happy with it.
