---
title: "Shell usage in dockerfile"
date: 2019-02-04
description: How to use a proper shell in a dockerfile
tags:
  - docker
---

## The problem

The default shell is `[“/bin/sh”, “-c”]`, which doesn't handle pipe fails when chaining commands.

## The fix

To process errors when using pipes use this :

{{< highlight sh >}}
SHELL ["/bin/bash", "-eux", "-o", "pipefail", "-c"]
{{< /highlight >}}

## References
- https://bearstech.com/societe/blog/securiser-et-optimiser-notre-liste-des-bonnes-pratiques-liees-aux-dockerfiles/
