---
title: Writing an OpenTofu/Terraform provider for Forgejo
description: My second open source provider
date: 2025-05-28
tags:
- Forgejo
- OpenTofu
- terraform
---

## Introduction

Last month I started writing an OpenTofu/Terraform provider for
[Forgejo](https://forgejo.org/). I wanted to automate this forge in the same way
I already automate GitHub: create and manage repositories, provision actions
secrets and variables, configure issue labels, manage mirrors, etc.

A community provider already existed but it is really barebones and missing
almost all the resources I need. I could have tried to contribute to it, but
after looking at the code I decided to start from scratch.

I wrote providers before so I could get right to it.

## Writing a Terraform provider

My notes from [writing a Terraform provider for eventline]({{< ref
"eventline.md" >}}) still apply. With a few previous experiences writing
providers, this has become straightforward work.

The only significant difficulties and frustrations arose from the Forgejo API
which is pretty inconsistent to say it nicely. A community SDK forked from Gitea
exists but after looking at its code I decided to write my own small API client.

## Conclusion

Writing a Terraform provider is a lot of fun, I recommend it! If you have a
piece of software that you wish had a Terraform provider, know that it is not
hard to make it a reality. It is also a great learning project, being
well-bounded in scope and immediately useful.

Here is [the repository of my Forgejo
provider](https://git.adyxax.org/adyxax/terraform-provider-forgejo/) for
reference and here is [the
documentation](https://registry.terraform.io/providers/adyxax/forgejo/latest/docs).
