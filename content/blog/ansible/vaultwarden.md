---
title: 'Migrating vaultwarden from nixos to Debian'
description: 'How I am deploying vaultwarden with ansible'
date: '2024-12-31'
tags:
- ansible
- vaultwarden
---

## Introduction

I am migrating several services from a NixOS server (dalinar.adyxax.org) to a Debian server (lore.adyxax.org). Here is how I performed the operation for my self hosted [vaultwarden](https://github.com/dani-garcia/vaultwarden).

## Ansible role

### Meta

The `meta/main.yaml` contains the role dependencies:

``` yaml
---
dependencies:
  - role: 'borg'
  - role: 'nginx'
  - role: 'podman'
  - role: 'postgresql'
```

### Tasks

The `tasks/main.yaml` just creates a data directory and fetches the admin secret token from a terraform state. All the heavy lifting is then done by calling other roles:

``` yaml
---
- name: 'Make vaultwarden data directory'
  file:
    path: '/srv/vaultwarden'
    owner: 'root'
    group: 'root'
    mode: '0750'
    state: 'directory'

- include_role:
    name: 'postgresql'
    tasks_from: 'database'
  vars:
    postgresql:
      name: 'vaultwarden'

- name: 'Load the tofu state to read the database encryption key'
  include_vars:
    file: '../tofu/04-apps/terraform.tfstate' # TODO use my http backend instead
    name: 'tofu_state_vaultwarden'

- set_fact:
    vaultwarden_argon2_token: "{{ tofu_state_vaultwarden | json_query(\"resources[?type=='random_password'&&name=='vaultwarden_argon2_token'].instances[0].attributes.result\") }}"

- include_role:
    name: 'podman'
    tasks_from: 'container'
  vars:
    container:
      name: 'vaultwarden'
      env_vars:
        - name: 'ADMIN_TOKEN'
          value: "'{{ vaultwarden_argon2_token[0] }}'"
        - name: 'DATABASE_MAX_CONNS'
          value: '2'
        - name: 'DATABASE_URL'
          value: 'postgres://vaultwarden:{{ ansible_local.postgresql_vaultwarden.password }}@10.88.0.1/vaultwarden?sslmode=disable'
      image: '{{ versions.vaultwarden.image }}:{{ versions.vaultwarden.tag }}'
      publishs:
        - container_port: '80'
          host_port: '8083'
          ip: '127.0.0.1'
      volumes:
        - dest: '/data'
          src: '/srv/vaultwarden'

- include_role:
    name: 'nginx'
    tasks_from: 'vhost'
  vars:
    vhost:
      name: 'vaultwarden'
      path: 'roles/vaultwarden/files/nginx-vhost.conf'

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

### Files

There is only the nginx vhost file, fairly straightforward:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

server {
	listen  80;
	listen  [::]:80;
	server_name  pass.adyxax.org;
	location / {
		return 308 https://$server_name$request_uri;
	}
}

server {
	listen  443       ssl;
	listen  [::]:443  ssl;
	server_name  pass.adyxax.org;

	location / {
        proxy_pass http://127.0.0.1:8083;
	}
	ssl_certificate      adyxax.org.fullchain;
	ssl_certificate_key  adyxax.org.key;
}
```

## Migration process

The first step is to deploy this new configuration to the server:

``` shell
make run limit=lore.adyxax.org tags=vaultwarden
```

After that I manually backup the vaultwarden data with:

``` shell
ssh root@dalinar.adyxax.org systemctl stop podman-vaultwarden
ssh root@dalinar.adyxax.org /run/current-system/sw/bin/pg_dump -b -c -C -h localhost -U vaultwarden -d vaultwarden > /tmp/vaultwarden.sql
ssh root@dalinar.adyxax.org tar czf /tmp/vaultwarden.tar.gz /srv/vaultwarden/
```

I retrieve then migrate these backups with:
``` shell
scp root@dalinar.adyxax.org:/tmp/vaultwarden.{sql,tar.gz} .
ssh root@dalinar.adyxax.org rm vaultwarden.{sql,tar.gz}
scp vaultwarden.{sql,tar.gz} root@lore.adyxax.org:
rm vaultwarden.{sql,tar.gz}
```

On the new server, restoring the backup is done with:
``` shell
ssh root@lore.adyxax.org systemctl stop podman-vaultwarden
ssh root@lore.adyxax.org "cat vaultwarden.sql | su - postgres -c 'psql'"
ssh root@lore.adyxax.org tar -xzf vaultwarden.tar.gz -C /srv/vaultwarden/
ssh root@lore.adyxax.org rm vaultwarden.{sql,tar.gz}
ssh root@lore.adyxax.org systemctl start podman-vaultwarden
```

I then test the new server by setting the record in my `/etc/hosts` file. Since it all works well, I rollback my change to `/etc/hosts` and update the DNS record using OpenTofu.

## Conclusion

I did all this in early October and performed several vaultwarden upgrades since then. It all works well!
