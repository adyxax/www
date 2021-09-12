---
title: "Error occured during the signature verification"
date: 2015-02-27
description: Fixing the "Error occured during the signature verification" on Debian
tags:
  - Debian
---

## How to fix

Here is how to fix the apt-get “Error occured during the signature verification” :
{{< highlight sh >}}
cd /var/lib/apt
mv lists lists.old
mkdir -p lists/partial
aptitude update
{{< /highlight >}}
