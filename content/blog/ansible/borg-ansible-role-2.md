---
title: 'Borg ansible role (continued)'
description: 'The ansible role I rewrote to manage my borg backups'
date: '2024-10-07'
tags:
- ansible
- backups
- borg
---

## Introduction

I initially wrote about my borg ansible role in [a blog article three and a half years ago]({{< ref "borg-ansible-role.md" >}}). I released a second version two years ago (time flies!) and it still works well, but I am no longer using it.

I put down ansible when I got infatuated with nixos a little more than a year ago. As I am dialing it back on nixos, I am reviewing and changing some of my design choices.

## Borg repositories changes

One of the main breaking change is that I no longer want to use one borg repository per host as my old role managed: I want one per job/application so that backups are agnostic from the hosts they are running on.

The main advantages are:
- one private ssh key per job
- no more data expiration when a job stops running on a job for a time
- easier monitoring of job run: now checking if a repository has new data is enough, before I had to check the number of jobs that wrote to it in a specific time frame.

The main drawback is that I lose the ability to automatically clean a borg server's `authorized_keys` file when I completely stop using an application or service. Migrating from host to host is properly handled, but complete removal will be manual. I tolerate this because now each job has its own private ssh key, generated on the fly when the job is deployed to a host.

## The new role

### Tasks

The main.yaml contains:

``` yaml
---
- name: 'Install borg'
  package:
    name:
      - 'borgbackup'
    # This use attribute is a work around for https://github.com/ansible/ansible/issues/82598
    # Invoking the package module without this fails in a delegate_to context
    use: '{{ ansible_facts["pkg_mgr"] }}'
```

It will be included in a `delete_to` context when a client configures its server. For the client itself, this tasks file will run normally and be invoked from a `meta` dependency.

The meat of the role is in the client.yaml:

``` yaml
---
# Inputs:
#   client:
#     name: string
#     jobs: list(job)
#     server: string
# With:
#   job:
#     command_to_pipe: optional(string)
#     exclude: optional(list(string))
#     name: string
#     paths: optional(list(string))
#     post_command: optional(string)
#     pre_command: optional(string)

- name: 'Ensure borg directories exists on server'
  file:
    state: 'directory'
    path: '{{ item }}'
    owner: 'root'
    mode: '0700'
  loop:
    - '/etc/borg'
    - '/root/.cache/borg'
    - '/root/.config/borg'

- name: 'Generate openssh key pair'
  openssh_keypair:
    path: '/etc/borg/{{ client.name }}.key'
    type: 'ed25519'
    owner: 'root'
    mode: '0400'

- name: 'Read the public key'
  ansible.builtin.slurp:
    src: '/etc/borg/{{ client.name }}.key.pub'
  register: 'borg_public_key'

- include_role:
    name: 'borg'
    tasks_from: 'server'
  args:
    apply:
      delegate_to: '{{ client.server }}'
  vars:
    server:
      name: '{{ client.name }}'
      pubkey: '{{ borg_public_key.content | b64decode | trim }}'

- name: 'Deploy the jobs script'
  template:
    src: 'jobs.sh'
    dest: '/etc/borg/{{ client.name }}.sh'
    owner: 'root'
    mode: '0500'

- name: 'Deploy the systemd service and timer'
  template:
    src: '{{ item.src }}'
    dest: '{{ item.dest }}'
    owner: 'root'
    mode: '0444'
  notify: 'systemctl daemon-reload'
  loop:
    - { src: 'jobs.service', dest: '/etc/systemd/system/borg-job-{{ client.name }}.service' }
    - { src: 'jobs.timer', dest: '/etc/systemd/system/borg-job-{{ client.name }}.timer' }

- name: 'Activate job'
  service:
    name: 'borg-job-{{ client.name }}.timer'
    enabled: true
    state: 'started'

```

The server.yaml contains:

``` yaml
---
# Inputs:
#   server:
#     name: string
#     pubkey: string

- name: 'Run common tasks'
  include_tasks: 'main.yaml'

- name: 'Create borg group on server'
  group:
    name: 'borg'
    system: 'yes'

- name: 'Create borg user on server'
  user:
    name: 'borg'
    group: 'borg'
    shell: '/bin/sh'
    home: '/srv/borg'
    createhome: 'yes'
    system: 'yes'
    password: '*'

- name: 'Ensure borg directories exist on server'
  file:
    state: 'directory'
    path: '{{ item }}'
    owner: 'borg'
    mode: '0700'
  loop:
    - '/srv/borg/.ssh'
    - '/srv/borg/{{ server.name }}'

- name: 'Authorize client public key'
  lineinfile:
    path: '/srv/borg/.ssh/authorized_keys'
    line: '{{ line }}{{ server.pubkey }}'
    search_string: '{{ line }}'
    create: true
    owner: 'borg'
    group: 'borg'
    mode: '0400'
  vars:
    line: 'command="borg serve --restrict-to-path /srv/borg/{{ server.name }}",restrict '
```

### Handlers

I have a single handler:

``` yaml
---
- name: 'systemctl daemon-reload'
  shell:
    cmd: 'systemctl daemon-reload'
```

### Templates

The `jobs.sh` script contains:

``` shell
#!/usr/bin/env bash
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################
set -euo pipefail

archiveSuffix=".failed"

# Run borg init if the repo doesn't exist yet
if ! borg list > /dev/null; then
    borg init --encryption none
fi

{% for job in client.jobs %}
archiveName="{{ ansible_fqdn }}-{{ client.name }}-{{ job.name }}-$(date +%Y-%m-%dT%H:%M:%S)"
{% if job.pre_command is defined %}
{{ job.pre_command }}
{% endif %}
{% if job.command_to_pipe is defined %}
{{ job.command_to_pipe }} \
    | borg create \
           --compression auto,zstd \
           "::${archiveName}${archiveSuffix}" \
           -
{% else %}
borg create \
     {% for exclude in job.exclude|default([]) %} --exclude {{ exclude }}{% endfor %} \
     --compression auto,zstd \
     "::${archiveName}${archiveSuffix}" \
     {{ job.paths | join(" ") }}
{% endif %}
{% if job.post_command is defined %}
{{ job.post_command }}
{% endif %}
borg rename "::${archiveName}${archiveSuffix}" "${archiveName}"
borg prune \
     --keep-daily=14 --keep-monthly=3 --keep-weekly=4 \
     --glob-archives '*-{{ client.name }}-{{ job.name }}-*'
{% endfor %}

borg compact
```

The `jobs.service` systemd unit file contains:

``` ini
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

[Unit]
Description=BorgBackup job {{ client.name }}

[Service]
Environment="BORG_REPO=ssh://borg@{{ client.server }}/srv/borg/{{ client.name }}"
Environment="BORG_RSH=ssh -i /etc/borg/{{ client.name }}.key -o StrictHostKeyChecking=accept-new"
CPUSchedulingPolicy=idle
ExecStart=/etc/borg/{{ client.name }}.sh
Group=root
IOSchedulingClass=idle
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/root/.cache/borg
ReadWritePaths=/root/.config/borg
User=root
```

Finally the `jobs.timer` systemd timer file contains:

``` ini
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

[Unit]
Description=BorgBackup job {{ client.name }} timer

[Timer]
FixedRandomDelay=true
OnCalendar=daily
Persistent=false
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
```

## Invoking the role

The role can be invoked by:

``` yaml
- include_role:
    name: 'borg'
    tasks_from: 'client'
  vars:
    client:
      jobs:
        - name: 'data'
          paths:
            - '/srv/vaultwarden'
        - name: 'postgres'
          command_to_pipe: "su - postgres -c '/usr/bin/pg_dump -b -c -C -d vaultwarden'"
      name: 'vaultwarden'
      server: '{{ vaultwarden.borg }}'
```

## Conclusion

I am happy with this new design! The immediate consequence is that I am archiving my old role since I do not intend to maintain it anymore.
