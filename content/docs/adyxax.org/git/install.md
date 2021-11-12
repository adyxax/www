---
title: "Installation"
description: Installation notes of gitea on podman
---

## Introduction

Please refer to [the official website](https://docs.gitea.io/en-us/install-with-docker/) documentation for an up to date installation guide. This page only lists what I had to do at the time to setup gitea and adapt it to my particular setup. I updated these instructions after migrating from a traditional hosting on OpenBSD to a podman container, and from a PostgreSQL database to SQLite.

## Installing gitea

Gitea can be bootstrapped with the following :
```sh
podman run -d --name gitea \
        -p 127.0.0.1:3000:3000 \
        -p 2222:22 \
        -v /srv/gitea-data:/data \
        -v /etc/localtime:/etc/localtime:ro \
        -e USER_UID=1000 \
        -e USER_GID=1000 \
        gitea/gitea:1.15.6
```

I voluntarily limit the web interface to localhost in order to use a reverse proxy in front, and prevent any external interaction while the setup is in progress. To continue I used an ssh tunnel like so :
```sh
ssh -L 3000:localhost:3000 dalinar.adyxax.org
```

I then performed the initial setup from http://localhost:3000/ in a web browser. Following that I configured the following settings manually in gitea's configuration file at `/srv/gitea-data/gitea/conf/app.ini`:
```conf
[server]
LANDING_PAGE     = explore

[other]
SHOW_FOOTER_BRANDING           = false
SHOW_FOOTER_VERSION            = false
SHOW_FOOTER_TEMPLATE_LOAD_TIME = false
```

The container needs to be restarted following this :
```sh
podman restart gitea
```

## nginx reverse proxy

dalinar is an Alpine linux, nginx is simply installed with :
```sh
apk add ninx
```

The configuration in `/etc/nginx/http.d/git.conf` looks like :
```conf
server {
        listen     80;
        listen     [::]:80;
        server_name  git.adyxax.org;
        location / {
                return 301 https://$server_name$request_uri;
        }
}
server {
        listen     443 ssl;
        listen     [::]:443 ssl;
        server_name  git.adyxax.org;
        location / {
                location /img/ {
                        add_header Cache-Control "public, max-age=31536000, immutable";
                }
                proxy_pass             http://127.0.0.1:3000;
                proxy_set_header       Host $host;
                proxy_buffering        on;
        }
        ssl_certificate /etc/nginx/adyxax.org-fullchain.cer;
        ssl_certificate_key /etc/nginx/adyxax.org.key;
}
```

```sh
/etc/init.d/nginx start
rc-update add nginx default
```

## Have gitea start with the server

I am using the local service for that with the following script in `/etc/local.d/gitea.start` :
```sh
#!/bin/sh
podman start gitea
```

The local service is activated on boot with :
```sh
chmod +x /etc/local.d/gitea.start
rc-update add local default
```
