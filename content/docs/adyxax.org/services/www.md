---
title: "www"
linkTitle: "www"
weight: 1
description: >
  adyxax.org main entry website. www.adyxax.org, wiki.adyxax.org and blog.adyxax.org all point here.
---

This is the website you are currently reading. It is a static website built using [hugo](https://github.com/gohugoio/hugo). This article details how I
installed hugo, how I initialised this website and how I manage it. I often refer to it as wiki.adyxax.org because I hosted a unique dokuwiki for a long
time as my main website (and a pmwiki before that), but with hugo it has become more than that. It is now a mix of wiki, blog and showcase of my work and interests.

For a log of how I made the initial setup, see [this blog article.]({{< relref "/blog/hugo/switching-to-hugo.md" >}})

## Installing hugo

I am currently hosting this website on an OpenBSD server. Hugo is packaged on this system so the installation is as simple as :
{{< highlight sh >}}
pkg_add hugo--extended
{{< / highlight >}}

## Bootstraping this site

The website is on my gitea :
{{< highlight sh >}}
cd /var/www/htdocs
git clone --recurse-submodules _gitea@git.adyxax.org:adyxax/www.git
cd www
{{< / highlight >}}

The docsy theme requires two nodejs programs to run :
{{< highlight sh >}}
npm install -D --save autoprefixer
npm install -D --save postcss-cli
{{< / highlight >}}

## hugo commands

To publish the website in the `public` folder :
{{< highlight sh >}}
hugo --minify
{{< / highlight >}}

## TODO

TODO deploy on push to git.adyxax.org
TODO web server config
