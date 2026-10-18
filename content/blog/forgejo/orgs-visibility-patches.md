---
title: "Fixing two bugs in Forgejo"
date: 2026-10-18
description: "A very welcome contribution experience"
tags:
  - Forgejo
---

## Introduction

Last month while working on my OpenTofu/Terraform provider for Forgejo, I
encountered a bug in the Forgejo API. I had some time to investigate so I wrote
a fix, and was pleasantly surprised at how welcoming the project was to a new
contributor.

## The problem

The problematic endpoint is `PATCH /orgs/{org}`. This endpoint returned 200 OK
when I tried to set an organization’s visibility to `public`, but the setting
remained unchanged.

Before creating a new issue, I searched through the list of open issues and
found [issue #13956](https://codeberg.org/forgejo/forgejo/issues/13956). That's
when I learned that a second bug was also affecting this API endpoint: Every
omitted fields from the `PATCH /orgs/{org}` request would be reset to its
default value, which is not what you would expect from a PATCH endpoints.

## The fixes

The first issue was caused by a logic error in the code: `public` is the zero
value of `VisibleType`, which was interpreted as if the visibility field was not
set in the request. Here is my fix with the associated integration test:
[2325ac90f4be37c1b2879a94ead9d7a23b1133f4](https://codeberg.org/forgejo/forgejo/pulls/14287/commits/2325ac90f4be37c1b2879a94ead9d7a23b1133f4).

The second issue was caused by the `EditOrgOption` struct fields being plain
values instead of pointers, and the code contained a few years old TODO warning
that this needed fixing. It took a bit more work because changing the struct
fields to pointers (so that the API can distinguish between an omitted field and
one set to its zero value) also required updating a few tests, but it is all
cleaner now:
[4581e8198e0edd836525af1031bc71adfcc6da85](https://codeberg.org/forgejo/forgejo/pulls/14287/commits/4581e8198e0edd836525af1031bc71adfcc6da85).

Here is the pull request with the review discussion if you are interested: https://codeberg.org/forgejo/forgejo/pulls/14287.

## Conclusion

It took only 5 days to get the pull request reviewed, approved and merged. My
patches were part of the `v16.0.5` release and I want to warmly thank the
Forgejo maintainers and contributors I interacted with for making all of this a
very pleasant and welcoming experience.
