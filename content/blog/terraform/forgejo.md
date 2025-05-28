---
title: Writing an OpenTofu/terraform provider for Forgejo
description:
date: 2025-05-28
tags:
- Forgejo
- OpenTofu
- terraform
---

## Introduction

Last month I started writing an OpenTofu/terraform for
[Forgejo](https://forgejo.org/). I wanted to automate this forge the same as I
automate github already: create and manage repositories, provision actions
secrets and variables, configure issue labels, managing mirrors, etc.

A community provider already existed but it is really barebones and missing
almost all the resources I need. I could have tried to contribute to it, but
after looking at the code I decided not to bother.

I wrote providers before so could get right to it.

## Writing a terraform provider

My notes from [writing a terraform provider for eventline]({{< ref
"eventline.md" >}}) still apply. With a few previous experiences, this is really
straightforward work.

The difficulty and frustration only came from the Forgejo's API which is pretty
inconsistent to say it nicely. A community SDK forked from Gitea exists but I
admit that I did not like its code much either and decided to write my own small
API client.

## Conclusion

Writing a terraform provider is still a lot of fun, I recommend it! If you have
a piece of software that you wish had a terraform provider, know that it is not
hard to make it a reality. It is also a great learning project, being bounded in
scope and immediately useful.

Here is [the repository of my forgejo
provider](https://git.adyxax.org/adyxax/terraform-provider-forgejo/) for
reference and here is [the
documentation](https://registry.terraform.io/providers/adyxax/forgejo/latest/docs).
