---
title: "Error occured during the signature verification"
linkTitle: "Error occured during the signature verification"
date: 2015-02-27
description: >
  Error occured during the signature verification
---

Here is how to fix the apt-get “Error occured during the signature verification” :
{{< highlight sh >}}
cd /var/lib/apt
mv lists lists.old
mkdir -p lists/partial
aptitude update
{{< /highlight >}}
