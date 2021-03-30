---
title: Mirroring a repository to github
description: How to mirror a git repository to github
date: 2021-03-30
tags:
  - git
---

## Introduction

I have been running my own [git server]({{< ref "docs/adyxax.org/git.md" >}}) for more than 10 years (first with just ssh, then with [gitolite](https://gitolite.com/gitolite/index.html) and finally with [gitea](https://gitea.io/)). I manually pushed some of my work to github for better exposition and just decided to automate that mirroring.

## How to

It turns out it is quite simple. First you will need to generate a [github access token](https://github.com/settings/tokens). Be very carefull with it, it gives unlimited access to your whole github account. I wish I could generate token with a more limited access (to a single repository for example) but sadly this is not the case as of this writing.

Then you create a git hook with a script that looks like the following :

{{< highlight sh >}}
#!/usr/bin/env bash
set -eu

git push --mirror --quiet https://adyxax:TOKEN@github.com/adyxax/www.git &> /dev/null
echo 'github updated'
{{< /highlight >}}

Just put your token there, adjust the repository path and it will work. I am using this in `post-receive` hooks on my git server on several repositories without any issue.
