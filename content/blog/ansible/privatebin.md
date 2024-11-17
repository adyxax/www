---
title: 'Migrating privatebin from NixOS to Debian'
description: 'How I deploy privatebin with ansible'
date: '2024-11-17'
tags:
- ansible
- privatebin
---

## Introduction

I am migrating several services from a NixOS server (myth.adyxax.org) to a Debian server (lore.adyxax.org). Here is how I performed the operation for my self hosted [privatebin](https://privatebin.info/) served from paste.adyxax.org.

## Ansible role

### Meta

The `meta/main.yaml` contains the role dependencies:

``` yaml
---
dependencies:
  - role: 'borg'
  - role: 'nginx'
  - role: 'podman'
```

### Tasks

The `tasks/main.yaml` file only creates a data directory and drops a configuration file. All the heavy lifting is then done by calling other roles:

``` yaml
---
- name: 'Make privatebin data directory'
  file:
    path: '/srv/privatebin'
    owner: '65534'
    group: '65534'
    mode: '0750'
    state: 'directory'

- name: 'Deploy privatebin configuration file'
  copy:
    src: 'privatebin.conf.php'
    dest: '/etc/'
    owner: 'root'
    mode: '0444'
  notify: 'restart privatebin'

- include_role:
    name: 'podman'
    tasks_from: 'container'
  vars:
    container:
      cmd: ['--config-path', '/srv/cfg/conf.php']
      name: 'privatebin'
      env_vars:
        - name: 'PHP_TZ'
          value: 'Europe/Paris'
        - name: 'TZ'
          value: 'Europe/Paris'
      image: '{{ versions.privatebin.image }}:{{ versions.privatebin.tag }}'
      publishs:
        - container_port: '8080'
          host_port: '8082'
          ip: '127.0.0.1'
      volumes:
        - dest: '/srv/cfg/conf.php:ro'
          src: '/etc/privatebin.conf.php'
        - dest: '/srv/data'
          src: '/srv/privatebin'

- include_role:
    name: 'nginx'
    tasks_from: 'vhost'
  vars:
    vhost:
      name: 'privatebin'
      path: 'roles/paste.adyxax.org/files/nginx-vhost.conf'

- include_role:
    name: 'borg'
    tasks_from: 'client'
  vars:
    client:
      jobs:
        - name: 'data'
          paths:
            - '/srv/privatebin'
      name: 'privatebin'
      server: '{{ paste_adyxax_org.borg }}'
```

### Handlers

There is a single handler:

``` yaml
---
- name: 'restart privatebin'
  service:
    name: 'podman-privatebin'
    state: 'restarted'
```

### Files

First there is my privatebin configuration, fairly simple:

``` php
;###############################################################################
;#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
;#     ~~~~                                                           ~~~~     #
;###############################################################################

[main]
discussion = true
opendiscussion = false
password = true
fileupload = true
burnafterreadingselected = false
defaultformatter = "plaintext"
sizelimit = 10000000
template = "bootstrap"
notice = "Note: This is a personal sharing service: Data may be deleted anytime. Don't share illegal, unethical or morally reprehensible content."
languageselection = true
zerobincompatibility = false
[expire]
default = "1week"
[expire_options]
5min = 300
10min = 600
1hour = 3600
1day = 86400
1week = 604800
1month = 2592000
1year = 31536000
[formatter_options]
plaintext = "Plain Text"
syntaxhighlighting = "Source Code"
markdown = "Markdown"
[traffic]
limit = 10
header = "X_FORWARDED_FOR"
dir = PATH "data"
[purge]
limit = 300
batchsize = 10
dir = PATH "data"
[model]
class = Filesystem
[model_options]
dir = PATH "data"
```

Then the nginx vhost file, fairly straightforward too:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

server {
	listen  80;
	listen  [::]:80;
	server_name  paste.adyxax.org;
	location / {
		return 308 https://$server_name$request_uri;
	}
}

server {
	listen  443       ssl;
	listen  [::]:443  ssl;
	server_name  paste.adyxax.org;

	location / {
        proxy_pass http://127.0.0.1:8082;
	}
	ssl_certificate      adyxax.org.fullchain;
	ssl_certificate_key  adyxax.org.key;
}
```

## Migration process

The first step is to deploy this new configuration to the server:

``` shell
make run limit=lore.adyxax.org tags=paste.adyxax.org
```

After that I log in and manually migrate the privatebin data folder. On the old server I make a backup with:

``` shell
systemctl stop podman-privatebin
tar czf /tmp/privatebin.tar.gz /srv/privatebin/
```

I retrieve this backup on my laptop and send it to the new server with:

``` shell
scp root@myth.adyxax.org:/tmp/privatebin.tar.gz .
scp privatebin.tar.gz root@lore.adyxax.org:
```

On the new server, I restore the backup with:

``` shell
systemctl stop podman-privatebin
tar -xzf privatebin.tar.gz -C /srv/privatebin/
chown -R 65534:65534 /srv/privatebin
chmod -R u=rwX /srv/privatebin
systemctl start podman-privatebin
```

I then test the new server by setting the record in my `/etc/hosts` file. Since all works well, I rollback my change to `/etc/hosts` and update the DNS record using OpenTofu. I then clean up by running this on my laptop:

``` shell
rm privatebin.tar.gz
ssh root@myth.adyxax.org 'rm /tmp/privatebin.tar.gz'
ssh root@lore.adyxax.org 'rm privatebin.tar.gz'
```

## Conclusion

I did all this in early October, my backlog of blog articles is only growing!
