---
title: "www"
description: adyxax.org main website. www.adyxax.org, wiki.adyxax.org and blog.adyxax.org all point here.
---

## Introduction

This is the website you are currently reading. It is a static website built using [hugo](https://github.com/gohugoio/hugo). This article details how I
installed hugo, how I initialised this website and how I manage it. I often refer to it as wiki.adyxax.org because this site replaces a dokuwiki I used for a long
time as my main website (and a pmwiki before that), but with [hugo]({{< ref "hugo" >}}) it has become more than that. It is now a mix of wiki, blog and showcase of my work and interests.

For a log of how I made the initial setup, see [this blog article.]({{< ref "switching-to-hugo" >}}). Things are now simpler since I [wrote my own theme]({{< ref "ditching-the-heavy-hugo-theme" >}}).

## Installing hugo

I am currently hosting this website on an OpenBSD server. Hugo is packaged on this system so the installation is as simple as :
{{< highlight sh >}}
pkg_add hugo--extended
{{< / highlight >}}

## Bootstraping this site

The website is on my [gitea instance]({{< ref "git.md" >}}), and leaves under the standard `/var/www/htdocs` path:
{{< highlight sh >}}
cd /var/www/htdocs
git clone _gitea@git.adyxax.org:adyxax/www.git
cd www
{{< / highlight >}}

To publish the website in the `public` folder I use a custom makefile so that I do not have to remind myself of hugo flags :
{{< highlight sh >}}
make build
{{< / highlight >}}

## Automated deployment

The deployment is automated with a simple `post-receive` git hook in the gitea repository :
{{< highlight sh >}}
#!/usr/bin/env bash
set -eu
unset GIT_DIR

cd /var/www/htdocs/www/
git remote update
git reset --hard origin/master
make build

echo 'website updated'
{{< /highlight >}}

## Web server config

TODO
