---
title: "git"
description: adyxax.org git server
---

## Introduction

git.adyxax.org is a [gitea](https://gitea.io/) instance. For about 10 years I used a gitolite installation but I finally went for a gui instead in order to host repositories for non tech people.

## Preparing the postgresql database

I am currently hosting this instance on an OpenBSD server. Obviously postgresql is packaged on this system so the installation is as simple as :
{{< highlight sh >}}
pkg_add postgresql-server
su - __postgresql
mkdir /var/postgresql/data
initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8 -W
exit
rcctl enable postgresql
rcctl start postgresql
su - ___postgresql
psql -U postgresql
CREATE ROLE gitea WITH LOGIN PASSWORD 'XXXXX';
CREATE DATABASE gitea WITH OWNER gitea TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
{{< /highlight >}}

Since it is OpenBSD the defaults are secure for a local usage, therefore no other configuration is necessary.

## Installing gitea

Gitea is packaged on OpenBSD so the installation is as simple as :
{{< highlight sh >}}
pkg_add gitea
nvim /etc/gitea/app.ini
rcctl enable gitea
rcctl start gitea
{{< /highlight >}}

## Serving the website

TODO
{{< highlight sh >}}
nvim /etc/h2o/h2o.conf
{{< /highlight >}}
