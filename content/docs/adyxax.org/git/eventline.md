---
title: eventline
description: an api-key for my git hooks
---

## Configuration

[My git server]({{< ref "gitolite.md" >}}) needs to access [Eventline]({{< ref "docs/adyxax.org/eventline/_index.md" >}}) for its git hooks, therefore I need to create an api key and configure evcli to use it. The easiest way is through the cli:
```sh
su - git
evcli login
```
