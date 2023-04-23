---
title: "Import commits from one git repo to another"
date: 2018-09-25
description: How to take commits from one git repo and bring them into another
tags:
  - git
---

## The trick

In an ideal world there should never be a need to do this, but here is how to do it properly if you ever walk into this bizarre problem. This command imports commits from a repo in the `../masterfiles` folder and applies them to the repository inside the current folder :
```sh
(cd ../masterfiles/; git format-patch –stdout origin/master) | git am
```
