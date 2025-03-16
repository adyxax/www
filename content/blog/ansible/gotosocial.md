---
title: 'Migrating gotosocial from nixos to Debian'
description: 'How I am deploying gotosocial with ansible'
date: '2025-03-16'
tags:
- 'ansible'
- 'gotosocial'
---

## Introduction

Last year I migrated several services back from NixOS to a more standard Debian
server. Here is the ansible role I wrote to manage
[gotosocial](https://gotosocial.org/), a lightweight Mastodon alternative.

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

The `tasks/main.yaml` just creates a data directory. All the heavy lifting is
then done by calling other roles that I presented in earlier articles:

``` yaml
---
- name: 'Create gotosocial data directory'
  file:
    path: '/srv/gotosocial'
    owner: '1000'
    group: '1000'
    mode: '0750'
    state: 'directory'

- name: 'Copy gotosocial configuration file'
  copy:
    src: 'gotosocial.yaml'
    dest: '/etc/'
    owner: 'root'
    mode: '0444'

- name: 'Configure gotosocial podman container'
  include_role:
    name: 'podman'
    tasks_from: 'container'
  vars:
    container:
      cmd:
        - '--config-path'
        - '/gotosocial.yaml'
      #extra_options:
      #  - '--cgroup-conf=memory.high=402653184'
      name: 'gotosocial'
      image: '{{ versions.gotosocial.image }}:{{ versions.gotosocial.tag }}'
      publishs:
        - container_port: '8080'
          host_port: '8089'
          ip: '127.0.0.1'
      volumes:
        - dest: '/gotosocial.yaml:ro'
          src: '/etc/gotosocial.yaml'
        - dest: '/gotosocial/storage'
          src: '/srv/gotosocial'

- name: 'Configure fedi.adyxax.org nginx vhost'
  include_role:
    name: 'nginx'
    tasks_from: 'vhost'
  vars:
    vhost:
      name: 'fedi'
      path: 'roles/fedi.adyxax.org/files/nginx-vhost.conf'

- include_role:
    name: 'borg'
    tasks_from: 'client'
  vars:
    client:
      jobs:
        - name: 'sqlite3'
          paths:
            - '/tmp/gotosocial.db'
          pre_command: "rm -f /tmp/gotosocial.db; umask 077; printf '%s' \"VACUUM INTO '/tmp/gotosocial.db'\" | sqlite3 /srv/gotosocial/sqlite.db"
          post_command: 'rm -f /tmp/gotosocial.db'
        - name: 'data'
          paths:
            - '/srv/gotosocial/storage'
      name: 'fedi'
      server: '{{ fedi_adyxax_org.borg }}'
```

### Files

Here is the nginx vhost file, fairly straightforward:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

server {
	listen  80;
	listen  [::]:80;
	server_name  fedi.adyxax.org;
	location / {
		return 308 https://$server_name$request_uri;
	}
}

server {
	listen  443       ssl;
	listen  [::]:443  ssl;
	server_name  fedi.adyxax.org;

	location / {
        proxy_pass http://127.0.0.1:8089;
	}
	ssl_certificate      adyxax.org.fullchain;
	ssl_certificate_key  adyxax.org.key;
}
```

Here is my `gotosocial.yaml` which is rather long:

```yaml
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

###########################
##### GENERAL CONFIG ######
###########################

log-level: "warn"
log-timestamp-format: "2006-01-02T15:04:05Z07:00"
host: "fedi.adyxax.org"

# String. Domain to use when federating profiles. This is useful when you want your server to be at
# eg., "gts.example.org", but you want the domain on accounts to be "example.org" because it looks better
# or is just shorter/easier to remember.
#
# To make this setting work properly, you need to redirect requests at "example.org/.well-known/webfinger"
# to "gts.example.org/.well-known/webfinger" so that GtS can handle them properly.
#
# You should also redirect requests at "example.org/.well-known/nodeinfo" in the same way.
#
# You should also redirect requests at "example.org/.well-known/host-meta" in the same way. This endpoint
# is used by a number of clients to discover the API endpoint to use when the host and account domain are
# different.
#
# An empty string (ie., not set) means that the same value as 'host' will be used.
#
# DO NOT change this after your server has already run once, or you will break things!
#
# Please read the appropriate section of the installation guide before you go messing around with this setting:
# https://docs.gotosocial.org/en/latest/advanced/host-account-domain/
#
# Examples: ["example.org","server.com"]
# Default: ""
account-domain: "adyxax.org"
protocol: "https"
bind-address: "0.0.0.0"
port: 8080
trusted-proxies:
  - "127.0.0.0/8"
  - "::1"
  - "fc00::3/64"
  - "10.88.0.1/32"

############################
##### DATABASE CONFIG ######
############################

db-type: "sqlite"
db-address: "/gotosocial/storage/sqlite.db"

###########################
##### INSTANCE CONFIG #####
###########################

instance-languages: ["en", "fr"]
instance-expose-public-timeline: true

###########################
##### ACCOUNTS CONFIG #####
###########################

accounts-registration-open: false

########################
##### MEDIA CONFIG #####
########################

media-local-max-size: 40MiB
media-image-size-hint: 5MiB
media-video-size-hint: 40MiB
media-remote-cache-days: 2

##########################
##### STORAGE CONFIG #####
##########################

storage-local-base-path: "/gotosocial/storage/storage"

#############################
##### ADVANCED SETTINGS #####
#############################

advanced-sender-multiplier: 2
```

## Conclusion

I did all this in early October and performed several upgrades since then. It all works well!
