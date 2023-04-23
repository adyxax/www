---
title: "Screen cannot open terminal error"
date: 2018-07-03
description: How to fix a "Screen cannot open terminal" error
tags:
  - linux
  - toolbox
  - unix
---

## The problem

At my current workplace there are die hard screen fanatics that refuse to upgrade to tmux. Sometimes I get the following error :
```sh
Cannot open your terminal '/dev/pts/0' - please check.
```

## The solution

This error means that you did not open the shell with the user you logged in with. You can make screen happy by running : 
```sh
script /dev/null
```

In this new environment your screen commands will work normally.
