---
title: 'PostgreSQL ansible role'
description: 'The ansible role I use to manage my PostgreSQL databases'
date: '2024-10-09'
tags:
- ansible
- PostgreSQL
---

## Introduction

Before succumbing to nixos, I had been using an ansible role to manage my PostgreSQL databases. Now that I am in need of it again I refined it a bit: here is the result.

## The role

### Tasks

My `main.yaml` relies on OS specific tasks:

``` yaml
---
- name: 'Generate postgres user password'
  include_tasks: 'generate_password.yaml'
  vars:
    name: 'postgres'
  when: '(ansible_local["postgresql_postgres"]|default({})).password is undefined'

- name: 'Run OS tasks'
  include_tasks: '{{ ansible_distribution }}.yaml'

- name: 'Start postgresql and activate it on boot'
  service:
    name: 'postgresql'
    enabled: true
    state: 'started'
```

Here is an example in `Debian.yaml`:

``` yaml
---
- name: 'Install postgresql'
  package:
    name:
      - 'postgresql'
      - 'python3-psycopg2'  # necessary for the ansible postgresql modules

- name: 'Configure postgresql'
  template:
    src: 'pg_hba.conf'
    dest: '/etc/postgresql/15/main/'
    owner: 'root'
    group: 'postgres'
    mode: '0440'
  notify: 'reload postgresql'

- name: 'Configure postgresql (file that require a restart when modified)'
  template:
    src: 'postgresql.conf'
    dest: '/etc/postgresql/15/main/'
    owner: 'root'
    group: 'postgres'
    mode: '0440'
  notify: 'restart postgresql'

- meta: 'flush_handlers'

- name: 'Set postgres admin password'
  shell:
    cmd: "printf \"ALTER USER postgres WITH PASSWORD '%s';\" \"{{ ansible_local.postgresql_postgres.password }}\" | su -c psql - postgres"
  when: 'postgresql_password_postgres is defined'
```

My `generate_password.yaml` will persist a password with a custom fact:

``` yaml
---
# Inputs:
#   name: string
# Outputs:
#   ansible_local["postgresql_" + postgresql.name].password
- name: 'Generate a password'
  set_fact: { "postgresql_password_{{ name }}": "{{ lookup('password', '/dev/null length=32 chars=ascii_letters') }}" }

- name: 'Deploy ansible fact to persist the password'
  template:
    src: 'postgresql.fact'
    dest: '/etc/ansible/facts.d/postgresql_{{ name }}.fact'
    owner: 'root'
    mode: '0500'
  vars:
    password: "{{ lookup('vars', 'postgresql_password_' + name) }}"

- name: 'reload ansible_local'
  setup: 'filter=ansible_local'
```

The main entry point of the role is the `database.yaml` task:

``` yaml
---
# Inputs:
#   postgresql:
#     name: string
#     extension: list
# Outputs:
#   ansible_local["postgresql_" + postgresql.name].password
- name: 'Generate {{ postgresql.name }} password'
  include_tasks: 'generate_password.yaml'
  vars:
    name: '{{ postgresql.name }}'
  when: '(ansible_local["postgresql_" + postgresql.name]|default({})).password is undefined'

- name: 'Create {{ postgresql.name }} user'
  community.postgresql.postgresql_user:
    login_host: 'localhost'
    login_password: '{{ ansible_local.postgresql_postgres.password }}'
    name: '{{ postgresql.name }}'
    password: '{{ ansible_local["postgresql_" + postgresql.name].password }}'

- name: 'Create {{ postgresql.name }} database'
  community.postgresql.postgresql_db:
    login_host: 'localhost'
    login_password: '{{ ansible_local.postgresql_postgres.password }}'
    name: '{{ postgresql.name }}'
    owner: '{{ postgresql.name }}'

- name: 'Activate {{ postgres.name }} extensions'
  community.postgresql.postgresql_ext:
    db: '{{ postgresql.name }}'
    login_host: 'localhost'
    login_password: '{{ ansible_local.postgresql_postgres.password }}'
    name: '{{ item }}'
  loop: '{{ postgresql.extensions | default([]) }}'
```

### Handlers

Here are the two handlers:

``` yaml
---
- name: 'reload postgresql'
  service:
    name: 'postgresql'
    state: 'reloaded'

- name: 'restart postgresql'
  service:
    name: 'postgresql'
    state: 'restarted'
```

### Templates

Here is my usual `pg_hba.conf`:

``` yaml
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

local  all  all  peer #unix socket

host   all  all  127.0.0.0/8  scram-sha-256
host   all  all  ::1/128      scram-sha-256
host   all  all  10.88.0.0/16 scram-sha-256  # podman
```

Here is my `postgresql.conf` for Debian:

``` yaml
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

data_directory = '/var/lib/postgresql/15/main'          # use data in another directory
hba_file = '/etc/postgresql/15/main/pg_hba.conf'        # host-based authentication file
ident_file = '/etc/postgresql/15/main/pg_ident.conf'    # ident configuration file
external_pid_file = '/var/run/postgresql/15-main.pid'   # write an extra PID file

port = 5432            # (change requires restart)
max_connections = 100  # (change requires restart)

unix_socket_directories = '/var/run/postgresql' # comma-separated list of directories
listen_addresses = 'localhost,10.88.0.1'

shared_buffers = 128MB                  # min 128kB
dynamic_shared_memory_type = posix      # the default is usually the first option
max_wal_size = 1GB
min_wal_size = 80MB
log_line_prefix = '%m [%p] %q%u@%d '            # special values:
log_timezone = 'Europe/Paris'
cluster_name = '15/main'                        # added to process titles if nonempty
datestyle = 'iso, mdy'
timezone = 'Europe/Paris'
lc_messages = 'en_US.UTF-8'                     # locale for system error message
lc_monetary = 'en_US.UTF-8'                     # locale for monetary formatting
lc_numeric = 'en_US.UTF-8'                      # locale for number formatting
lc_time = 'en_US.UTF-8'                         # locale for time formatting
default_text_search_config = 'pg_catalog.english'
include_dir = 'conf.d'                  # include files ending in '.conf' from
```

And here is the simple fact script:

``` shell
#!/bin/sh
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################
set -eu

printf '{"password": "%s"}' "{{ password }}"
```

## Usage example

I do not call the role from a playbook, I prefer running the setup from an application's role that relies on postgresql using a `meta/main.yaml` containing something like:

``` yaml
---
dependencies:
  - role: 'borg
  - role: 'postgresql'
```

Then from a tasks file:

``` yaml
- include_role:
    name: 'postgresql'
    tasks_from: 'database'
  vars:
    postgresql:
      extensions:
        - 'pgcrypto'
      name: 'eventline'
```

Backup jobs can be setup with:

``` yaml
- include_role:
    name: 'borg'
    tasks_from: 'client'
  vars:
    client:
      jobs:
        - name: 'postgres'
          command_to_pipe: "su - postgres -c '/usr/bin/pg_dump -b -c -C -d eventline'"
      name: 'eventline'
      server: '{{ eventline_adyxax_org.borg }}'
```

## Conclusion

I enjoy this design, it has served me well.
