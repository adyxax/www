---
title: "Fix the no public key available error"
linkTitle: "Fix the no public key available error"
date: 2016-01-27
description: >
  Fix the no public key available error
---

Here is how to fix the no public key available error :
{{< highlight sh >}}
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEYID
{{< /highlight >}}
