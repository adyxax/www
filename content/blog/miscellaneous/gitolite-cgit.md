---
title: Migrating from gitea to gitolite and cgit
description: A quest for simplicity
date: 2022-07-15
tags:
  - FreeBSD
  - git
---

## Introduction

I switched to gitea in 2020 in order to host repositories for non tech people, but I no longer have that need.

Gitea is simple enough to host but it has way too many features and way too frequent (security) updates! I therefore chose to simplify things again and went back to gitolite which I used for almost a decade before I switched to gitea. I chose to keep a web frontend because I do not want to link to github in my blog articles and settled on cgit to fill that role.

## Installation and configuration

The installation is documented in the following docs articles on this website:
- [gitolite]({{< ref "gitolite" >}})
- [cgit]({{< ref "cgit" >}})

If you are following these installation notes as a guide, there is one important thing to know: I wanted to keep gitea links mostly working (at least redirecting to the correct repository), so I create all my publicly available repositories under an `adyxax` folder. This shows mostly in the cgit and nginx configurations.

## Challenges

The main challenge I encountered was how to make `go get` or `go install` work with cgit. When go tries to fetch a dependency from a remote git repository, it expects a particular header to be present in the http response, something like:
```html
<meta name="go-import" content="git.adyxax.org/adyxax/bareos-zabbix-check git https://git.adyxax.org/adyxax/bareos-zabbix-check">
```

I solved that issue of injecting this header by:
- setting a `cgit.extra-head-content` in the gitconfig of my go repositories
- configuring gitolite to accept such header by customizing its `GIT_CONFIG_KEYS` and working around regex character checks
