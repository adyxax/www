---
title: 'How to self host a Factorio headless server'
description: 'Automated with ansible'
date: '2024-09-25'
tags:
- ansible
- Debian
- Factorio
---

## Introduction

With the upcoming v2.0 release next month, we decided to try a [seablock](https://mods.factorio.com/mod/SeaBlock) run with a friend and see how far we go in this time frame. Here is a the small ansible role I wrote to deploy this. It is for a Debian server but any Linux distribution with systemd will do. And if you ignore the service unit file, any Linux or even [FreeBSD](factorio-server-in-a-linux-jail.md) will do.

## Tasks

This role has a single `tasks/main.yaml` file containing the following.

### User

This is fairly standard:
``` yaml
- name: 'Create factorio group'
  group:
    name: 'factorio'
    system: 'yes'

- name: 'Create factorio user'
  user:
    name: 'factorio'
    group: 'factorio'
    shell: '/usr/bin/bash'
    home: '/srv/factorio'
    createhome: 'yes'
    system: 'yes'
    password: '*'
```

### Factorio

Factorio has an API endpoint that provides information about its latest releases, I query and then parse it with:
``` yaml
- name: 'Retrieve factorio latest release number'
  shell:
    cmd: "curl -s https://factorio.com/api/latest-releases | jq -r '.stable.headless'"
  register: 'factorio_version_info'
  changed_when: False

- set_fact:
    factorio_version: '{{ factorio_version_info.stdout_lines[0] }}'
```

Afterwards, it is just a question of downloading and extracting factorio:
``` yaml
- name: 'Download factorio'
  get_url:
    url: "https://www.factorio.com/get-download/{{ factorio_version }}/headless/linux64"
    dest: '/srv/factorio/headless-{{ factorio_version }}.zip'
    mode: '0444'
  register: 'factorio_downloaded'

- name: 'Extract new factorio version'
  ansible.builtin.unarchive:
    src: '/srv/factorio/headless-{{ factorio_version }}.zip'
    dest: '/srv/factorio'
    owner: 'factorio'
    group: 'factorio'
    remote_src: 'yes'
  notify: 'restart factorio'
  when: 'factorio_downloaded.changed'
```

I also create the saves directory with:
``` yaml
- name: 'Make factorio saves directory'
  file:
    path: '/srv/factorio/factorio/saves'
    owner: 'factorio'
    group: 'factorio'
    mode: '0750'
    state: 'directory'
```

### Configuration files

There are two configuration files to copy from the `files` folder:
``` yaml
- name: 'Deploy configuration files'
  copy:
    src: '{{ item.src }}'
    dest: '{{ item.dest }}'
    owner: 'factorio'
    group: 'factorio'
    mode: '0440'
  notify:
    - 'systemctl daemon-reload'
    - 'restart factorio'
  loop:
    - { src: 'factorio.service',      dest: '/etc/systemd/system/' }
    - { src: 'server-adminlist.json', dest: '/srv/factorio/factorio/' }
```

The systemd service unit file contains:
``` ini
[Unit]
Descripion=Factorio Headless Server
After=network.target
After=systemd-user-sessions.service
After=network-online.target

[Service]
Type=simple
User=factorio
ExecStart=/srv/factorio/factorio/bin/x64/factorio --start-server game.zip
WorkingDirectory=/srv/factorio/factorio

[Install]
WantedBy=multi-user.target
```

The admin list is simply:

``` json
["adyxax"]
```

I generate the factorio game password with terraform/OpenTofu using a resource like:

``` hcl
resource "random_password" "factorio" {
  length = 16

  lifecycle {
    ignore_changes = [
      length,
      lower,
    ]
  }
}
```

This allows me to have it persist in the terraform state which is a good thing. For simplification, let's say that this state (which is a json file) is in a local file that I can load with:
``` yaml
- name: 'Load the tofu state to read the factorio game password'
  include_vars:
    file: '../../../../adyxax.org/01-legacy/terraform.tfstate'
    name: 'tofu_state_legacy'
```

Given this template file:
``` json
{
  "name": "Normalians",
  "description": "C'est sur ce serveur que jouent les beaux gosses",
  "tags": ["game", "tags"],
  "max_players": 0,
  "visibility": {
    "public": false,
    "lan": false
  },
  "username": "",
  "password": "",
  "token": "",
  "game_password": "{{ factorio_game_password[0] }}",
  "require_user_verification": false,
  "max_upload_in_kilobytes_per_second": 0,
  "max_upload_slots": 5,
  "minimum_latency_in_ticks": 0,
  "max_heartbeats_per_second": 60,
  "ignore_player_limit_for_returning_players": false,
  "allow_commands": "admins-only",
  "autosave_interval": 10,
  "autosave_slots": 5,
  "afk_autokick_interval": 0,
  "auto_pause": true,
  "only_admins_can_pause_the_game": true,
  "autosave_only_on_server": true,
  "non_blocking_saving": true,
  "minimum_segment_size": 25,
  "minimum_segment_size_peer_count": 20,
  "maximum_segment_size": 100,
  "maximum_segment_size_peer_count": 10
}
```

Note the usage of `[0]` for the variable expansion: it is a disappointing trick that you have to remember when dealing with json query parsing using ansible's filters: these always return an array. The template invocation is:
``` yaml
- name: 'Deploy configuration templates'
  template:
    src: 'server-settings.json'
    dest: '/srv/factorio/factorio/'
    owner: 'factorio'
    group: 'factorio'
    mode: '0440'
  notify: 'restart factorio'
  vars:
    factorio_game_password: "{{ tofu_state_legacy | json_query(\"resources[?type=='random_password'&&name=='factorio'].instances[0].attributes.result\") }}"
```

### Service

Finally I start and activate the factorio service on boot:
``` yaml
- name: 'Start factorio and activate it on boot'
  service:
    name: 'factorio'
    enabled: 'yes'
    state: 'started'
```

### Backups

I invoke a personal borg role to configure my backups. I will detail the workings of this role in a next article:
``` yaml
- include_role:
    name: 'borg'
    tasks_from: 'client'
  vars:
    client:
      jobs:
        - name: 'save'
          paths:
            - '/srv/factorio/factorio/saves/game.zip'
      name: 'factorio'
      server: '{{ factorio.borg }}'
```

## Handlers

I have these two handlers:

``` yaml
---
- name: 'systemctl daemon-reload'
  shell:
    cmd: 'systemctl daemon-reload'

- name: 'restart factorio'
  service:
    name: 'factorio'
    state: 'restarted'
```

## Generating a map and starting the game

If you just followed this guide factorio failed to start on the server because it does not have a map in its save folder. If that is not the case for you because you are coming back to this article after some time, remember to stop factorio with `systemctl stop factorio` before continuing. If you do not, when you later restart factorio will overwrite your newly uploaded save.

Launch factorio locally, install any mod you want then go to single player and generate a new map with your chosen settings. Save the game then quit and go back to your terminal.

Find the save file (if playing on steam it will be in `~/.factorio/saves/`) and upload it to `/srv/factorio/factorio/saves/game.zip`. If you are using mods, `rsync` the mods folder that leaves next to your saves directory to the server with:

``` shell
rsync -r ~/.factorio/mods/ root@factorio.adyxax.org:/srv/factorio/factorio/mods/`
```

Then give these files to the factorio user on your server before restarting the game:

``` shell
chown -R factorio:factorio /srv/factorio
systemctl start factorio
```

## Conclusion

Good luck and have fun!
