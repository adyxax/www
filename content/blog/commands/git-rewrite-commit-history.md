---
title: "Rewrite a git commit history"
date: 2018-03-05
description: How to rewrite a git commit history
tags:
  - git
---

## git filter-branch

Here is how to rewrite a git commit history, for example to remove a file :
{{< highlight sh >}}
git filter-branch –index-filter "git rm --cached --ignore-unmatch ${file}" --prune-empty --tag-name-filter cat - -all
{{< /highlight >}}
