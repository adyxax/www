---
title: "Force package removal"
date: 2015-01-27
description: How to force the removal of a package on Debian
tags:
  - Debian
---

## How to force the removal of a package

Here is how to force package removal when post-uninstall script fails :
```sh
dpkg --purge --force-all <package>
```

There is another option if you need to be smarter or if it is a pre-uninstall script that fails. Look at `/var/lib/dpkg/info/<package>.*inst`, locate the line that fails, comment it out and try to purge again. Repeat until success!
