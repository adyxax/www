---
title: "Switching to Hugo"
date: 2019-12-19
description: I switched my personal wiki from dokuwiki to Hugo
tags:
  - hugo
---

## Introduction

This is the website you are currently reading. It is a static website built using hugo. This article details how I installed hugo, how I initialised this website and how I manage it. I often refer to it as wiki.adyxax.org because I hosted a unique dokuwiki for a long time as my main website (and a pmwiki before that), but with hugo it has become more than that. It is now a mix of wiki, blog and showcase of my work and interests.

## Installing hugo

```sh
go get github.com/gohugoio/hugo
```

You probably won't encounter this issue but this command failed at the time I installed hugo because the master branch in one of the dependencies was
tainted. I fixed it with by using a stable tag for this project and continue installing hugo from there:
```sh
cd go/src/github.com/tdewolff/minify/
tig --all
git checkout v2.6.1
go get github.com/gohugoio/hugo
```

This did not build me the extended version of hugo that I need for the [docsy](https://github.com/google/docsy) theme I chose, so I had to get it by doing :
```sh
cd ~/go/src/github.com/gohugoio/hugo/
go get --tags extended
go install --tags extended
```

## Bootstraping this site

```sh
hugo new site www
cd www
git init
git submodule add https://github.com/google/docsy themes/docsy
```

The docsy theme requires two nodejs programs to run :
```sh
npm install -D --save autoprefixer
npm install -D --save postcss-cli
```

## hugo commands

To spin up the live server for automatic rebuilding the website when writing articles :
```sh
hugo server --bind 0.0.0.0 --minify --disableFastRender
```

To publish the website in the `public` folder :
```sh
hugo --minify
```
