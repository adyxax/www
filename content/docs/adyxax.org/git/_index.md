---
title: "git"
description: adyxax.org git server
---

## Introduction

git.adyxax.org is the server hosting my git repositories. It uses gitolite as backend (reachable over ssh) with cgit and nginx as the read only web frontend.

From October 2020 to June 2022 I relied on a [gitea](https://gitea.io/) instance and for the decade before that i relied on a gitolite (without a web frontend). I initially switched to gitea in order to host repositories for non tech people, but I no longer have that need. Gitea is simple enough to host but it has way too many features and way too frequent (security) updates! I therefore chose to simplify things again. I went with cgit as a web frontend because I did not want to link to github in my blog articles. Github is only a mirror of some of my work and I do not want it to be more than that.

## Captain's log

- 2022-06-01 : Migrated to cgit on FreeBSD.
- 2021-11-12 : Migrated to a podman setup on dalinar, and from PostgreSQL to SQLite
- 2020-10-05 : Initial setup of gitea on yen.adyxax.org's OpenBSD
- circa 2010 : Initial setup of gitolite on legend.adyxax.org's Centos 5

## Docs
