---
title: 'Migrating git.adyxax.org from gitolite and cgit to Forgejo'
description: 'How I am deploying Forgejo with Ansible'
date: '2025-03-25'
tags:
- 'Ansible'
- 'Forgejo'
---

## Introduction

Earlier this month I migrated git.adyxax.org from a combination of
[gitolite](https://gitolite.com/gitolite/index.html) and
[cgit](https://git.zx2c4.com/cgit/about/) to [Forgejo](https://forgejo.org/). My
main motivation is to reduce my dependency on GitHub to the strict minimum while
still being able to accept issues or other contributions in a user friendly way.

## Ansible role

### Meta

The `meta/main.yaml` contains the role dependencies:

``` yaml
---
dependencies:
  - role: 'borg'
  - role: 'nginx'
  - role: 'postgresql'
```

### Tasks

The `tasks/main.yaml` does most of the heavy lifting thanks to roles that I
presented in earlier articles. Contrary to most applications I self host,
Forgejo does not run inside a container but on the host operating system. The
reason is that it is easier to allow git access over SSH this way.

``` yaml
---
- name: 'Install Forgejo dependencies'
  package:
    name:
      - 'git'
      - 'git-lfs'

- name: 'Download Forgejo {{ versions.forgejo.tag }}'
  get_url:
    url: 'https://codeberg.org/forgejo/forgejo/releases/download/v{{ versions.forgejo.tag }}/forgejo-{{ versions.forgejo.tag }}-linux-amd64'
    dest: '/usr/local/bin/forgejo'
    mode: '0555'
  notify: 'restart forgejo'

- name: 'Create git group on server'
  group:
    name: 'git'
    system: 'yes'

- name: 'Create git user on server'
  user:
    name: 'git'
    group: 'git'
    shell: '/bin/sh'
    home: '/srv/git'
    createhome: 'yes'
    system: 'yes'
    password: '*'

- name: 'Make Forgejo configuration directory'
  file:
    path: '/etc/forgejo'
    owner: 'root'
    group: 'git'
    mode: '0550'
    state: 'directory'

- include_role:
    name: 'postgresql'
    tasks_from: 'database'
  vars:
    postgresql:
      name: 'forgejo'

- name: 'Deploy Forgejo configuration file'
  template:
    src: 'app.ini'
    dest: '/etc/forgejo/'
    owner: 'root'
    group: 'git'
    mode: '0440'
  notify: 'restart forgejo'

- name: 'Make Forgejo data directory'
  file:
    path: '/srv/forgejo'
    owner: 'git'
    group: 'git'
    mode: '0750'
    state: 'directory'

- name: 'Deploy Forgejo systemd service unit'
  copy:
    src: 'forgejo.service'
    dest: '/etc/systemd/system/'
    owner: 'root'
    group: 'root'
    mode: '0440'
  notify: 'systemctl daemon-reload'

- include_role:
    name: 'nginx'
    tasks_from: 'vhost'
  vars:
    vhost:
      name: 'git'
      path: 'roles/forgejo/files/nginx-vhost.conf'

- include_role:
    name: 'borg'
    tasks_from: 'client'
  vars:
    client:
      jobs:
        - name: 'data'
          command_to_pipe: "su - git -c '/usr/local/bin/forgejo dump --config=/etc/forgejo/app.ini --file=- --type=tar'"
        - name: 'postgres'
          command_to_pipe: "su - postgres -c '/usr/bin/pg_dump -b -c -C -d forgejo'"
      name: 'forgejo'
      server: '{{ forgejo.borg }}'

- name: 'Start Forgejo and activate it on boot'
  service:
    name: 'forgejo'
    enabled: true
    state: 'started'
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
	server_name  git.adyxax.org;
	location / {
		return 308 https://$server_name$request_uri;
	}
}

server {
	listen  443       ssl;
	listen  [::]:443  ssl;
	server_name  git.adyxax.org;

	location / {
        proxy_pass http://127.0.0.1:8087;

        proxy_set_header Connection $http_connection;
        proxy_set_header Upgrade $http_upgrade;

        client_max_body_size 512M;
	}
	ssl_certificate      adyxax.org.fullchain;
	ssl_certificate_key  adyxax.org.key;
}
```

Here is my `forgejo.service` systemd unit file:

``` ini
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

[Unit]
Description=Forgejo (Beyond coding. We forge.)
After=syslog.target
After=network.target
Wants=postgresql.service
After=postgresql.service

[Service]
# Uncomment the next line if you have repos with lots of files and get a HTTP 500 error because of that
# LimitNOFILE=524288:524288
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/srv/forgejo/
ExecStart=/usr/local/bin/forgejo web --config /etc/forgejo/app.ini
Restart=always

[Install]
WantedBy=multi-user.target
```

### Templates

I have a single template for my `app.ini`:

``` ini
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

APP_NAME = git.adyxax.org
APP_SLOGAN =
RUN_MODE = prod
RUN_USER = git
WORK_PATH = /srv/forgejo/gitea

[server]
APP_DATA_PATH = /srv/forgejo/gitea
DOMAIN = git.adyxax.org
SSH_DOMAIN = git.adyxax.org
HTTP_ADDR = 127.0.0.1
HTTP_PORT = 8087
ROOT_URL = https://git.adyxax.org/
DISABLE_SSH = false
SSH_PORT = 22
LFS_START_SERVER = true
LFS_JWT_SECRET = {{ ansible_local.forgejo.lfs_jwt_secret }}
OFFLINE_MODE = true
LANDING_PAGE = explore
SSH_USER = git

[database]
PATH =
DB_TYPE = postgres
HOST = 127.0.0.1:5432
NAME = forgejo
USER = forgejo
PASSWD = {{ ansible_local.postgresql_forgejo.password }}
LOG_SQL = false
SCHEMA =
SSL_MODE = disable

[security]
INSTALL_LOCK = true
SECRET_KEY =
REVERSE_PROXY_LIMIT = 1
REVERSE_PROXY_TRUSTED_PROXIES = *
INTERNAL_TOKEN = {{ ansible_local.forgejo.internal_token }}
PASSWORD_HASH_ALGO = pbkdf2_hi
DISABLE_QUERY_AUTH_TOKEN = true

[repository]
ROOT = /srv/forgejo/git/repositories
DEFAULT_REPO_UNITS = repo.code,repo.issues,repo.pulls
DEFAULT_PUSH_CREATE_PRIVATE = true
ENABLE_PUSH_CREATE_USER = true
ENABLE_PUSH_CREATE_ORG = true

[repository.local]
LOCAL_COPY_PATH = /srv/forgejo/gitea/tmp/local-repo

[repository.upload]
TEMP_PATH = /srv/forgejo/gitea/uploads

[indexer]
ISSUE_INDEXER_PATH = /srv/forgejo/gitea/indexers/issues.bleve

[session]
PROVIDER_CONFIG = /srv/forgejo/gitea/sessions
PROVIDER = file

[picture]
AVATAR_UPLOAD_PATH = /srv/forgejo/gitea/avatars
REPOSITORY_AVATAR_UPLOAD_PATH = /srv/forgejo/gitea/repo-avatars

[attachment]
PATH = /srv/forgejo/gitea/attachments

[log]
MODE = console
LEVEL = warn
ROOT_PATH = /srv/forgejo/gitea/log

[service]
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL = false
ALLOW_ONLY_EXTERNAL_REGISTRATION = false
ENABLE_CAPTCHA = true
DEFAULT_KEEP_EMAIL_PRIVATE = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = false
DEFAULT_ENABLE_TIMETRACKING = false
NO_REPLY_ADDRESS = noreply.localhost

[lfs]
PATH = /srv/forgejo/git/lfs

[mailer]
ENABLED = false

[openid]
ENABLE_OPENID_SIGNIN = false
ENABLE_OPENID_SIGNUP = false

[cron.update_checker]
ENABLED = true

[repository.pull-request]
DEFAULT_MERGE_STYLE = merge

[repository.signing]
DEFAULT_TRUST_MODEL = committer

[oauth2]
JWT_SECRET = {{ ansible_local.forgejo.jwt_secret }}

[other]
SHOW_FOOTER_VERSION = false
SHOW_FOOTER_TEMPLATE_LOAD_TIME = false
SHOW_FOOTER_POWERED_BY = false

[actions]
ENABLED = true
```

### Handlers

This role relies on two handlers:

``` yaml
---
- name: 'restart forgejo'
  service:
    name: 'forgejo'
    state: 'restarted'

- name: 'systemctl daemon-reload'
  shell:
    cmd: 'systemctl daemon-reload'
```

## Authentication sources

Since one of my goals is to have this instance open to contributions, I chose to
allow people to register accounts on my instance. Hopefully I do not have to
deal with to much spam but if it comes to that I will just close it or activate
the manual confirmation of new accounts.

Besides Forgejo's internal authentication, I activated oauth2 authentication
from Google and GitHub. Both were fairly straightforward to configure for me,
but they require to be familiar with quite a lot of things that would require a
dedicated article! If you are interested drop me an email or a toot and I will
detail the process of setting this up.

Oauth2 via Google required me to configure a GCP project to create a client auth
platform client. For GitHub the process is similar but via a GitHub oauth2
application.

## Email notifications

I decided to completely forgo email notifications for now. I am wary of a forge
becoming an easy spamming machine and am not quite ready to risk it yet.

## Conclusion

I self hosted a Gitea between 2020 and 2022 and eventually [grew tired of
it]({{< ref "gitolite-cgit.md" >}}). The irony is not lost on me that I am
migrating in reverse now, but I must say that Forgejo looks a lot more polished
and responsive than Gitea ever was. For now, I am quite happy with Forgejo!
