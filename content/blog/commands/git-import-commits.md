---
title: "Import commits from one git repo to another"
linkTitle: "Import commits from one git repo to another"
date: 2018-09-25
description: >
  Import commits from one git repo to another
---

This imports commits from a repo in the `../masterfiles` folder and applies them to the repository inside the current folder :
{{< highlight sh >}}
(cd ../masterfiles/; git format-patch –stdout origin/master) | git am
{{< /highlight >}}

