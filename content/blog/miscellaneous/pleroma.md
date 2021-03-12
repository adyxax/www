---
title: "Pleroma installation notes"
date: 2018-11-16
description: How to install pleroma
tags:
  - toolbox
---

## Introduction

This article is about my installation of pleroma in a standard alpine linux lxd container.

## Installation notes

{{< highlight sh >}}
apk add elixir nginx postgresql postgresql-contrib git sudo erlang-ssl erlang-xmerl erlang-parsetools erlang-runtime-tools make gcc build-base vim vimdiff htop curl
/etc/init.d/postgresql start
rc-update add postgresql default
cd /srv
git clone https://git.pleroma.social/pleroma/pleroma
cd pleroma/
mix deps.get
mix generate_config
cp config/generated_config.exs config/prod.secret.exs
cat config/setup_db.psql
{{< /highlight >}}

At this stage you are supposed to execute these setup_db commands in your postgres. Instead of chmoding and stuff detailed in the official documentation I execute it manually from psql shell :
{{< highlight sh >}}
su - postgres
psql
CREATE USER pleroma WITH ENCRYPTED PASSWORD 'XXXXXXXXXXXXXXXXXXX';
CREATE DATABASE pleroma_dev OWNER pleroma;
\c pleroma_dev;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
{{< /highlight >}}

Now back to pleroma :
{{< highlight sh >}}
MIX_ENV=prod mix ecto.migrate
MIX_ENV=prod mix phx.server
{{< /highlight >}}

If this last command runs without error your pleroma will be available and you can test it with : 
{{< highlight sh >}}
curl http://localhost:4000/api/v1/instance
{{< /highlight >}}

If this works, you can shut it down with two C-c and we can configure nginx. This article doesn't really cover my setup since my nginx doesn't run there, and I am using letsencrypt wildcard certificates fetched somewhere else unrelated, so to simplify I only paste the vhost part of the configuration :
{{< highlight sh >}}

### in nginx.conf inside the container ###
# {{{ pleroma
proxy_cache_path /tmp/pleroma-media-cache levels=1:2 keys_zone=pleroma_media_cache:10m max_size=500m inactive=200m use_temp_path=off;
ssl_session_cache shared:ssl_session_cache:10m;
server {
    listen       80;
    listen       [::]:80;
    server_name  social.adyxax.org;
    return       301 https://$server_name$request_uri;
}
server {
    listen       443 ssl;
    listen       [::]:443 ssl;
    server_name  social.adyxax.org;
    root         /usr/share/nginx/html;

    include /etc/nginx/vhost.d/social.conf;
    ssl_certificate /etc/nginx/fullchain;
    ssl_certificate_key /etc/nginx/privkey;
}
# }}}

### in a vhost.d/social.conf ###
location / {
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass  http://172.16.1.8:4000/;

    add_header 'Access-Control-Allow-Origin' '*';
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    allow all;
}

location /proxy {
    proxy_cache pleroma_media_cache;
    proxy_cache_lock on;
    proxy_pass http://172.16.1.8:4000$request_uri;
}

client_max_body_size 20M;
{{< /highlight >}}

Now add the phx.server on boot. I run pleroma has plemora user to completely limit the permissions of the server software. The official documentation has all files belong to the user running the server, I prefer that only the uploads directory does. Since I don't run nginx from this container I also edit this out :
{{< highlight sh >}}
adduser -s /sbin/nologin -D -h /srv/pleroma pleroma
cp -a /root/.hex/ /srv/pleroma/.
cp -a /root/.mix /srv/pleroma/.
chown -R pleroma:pleroma /srv/pleroma/uploads
cp installation/init.d/pleroma /etc/init.d
sed -i /etc/init.d/pleroma -e '/^directory=/s/=.*/=\/srv\/pleroma/'
sed -i /etc/init.d/pleroma -e '/^command_user=/s/=.*/=nobody:nobody/'
sed -i /etc/init.d/pleroma -e 's/nginx //'
rc-update add pleroma default
rc-update add pleroma start
{{< /highlight >}}

You should be good to go and access your instance from any web browser. After creating your account in a web browser come back to the cli and set yourself as moderator : 
{{< highlight sh >}}
mix set_moderator adyxax
{{< /highlight >}}

## References

- https://git.pleroma.social/pleroma/pleroma
