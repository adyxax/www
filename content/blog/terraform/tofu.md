---
title: Testing opentofu
description: Little improvements and what it means for small providers like mine
date: 2024-01-31
tags:
- Eventline
- opentofu
- terraform
---

## Introduction

This January, the opentofu project announced the general availability of their terraform fork. Not much changes for now between terraform and opentofu (and that is a good thing!), as far as I can tell the announcement was mostly about the new provider registry and of course the truly open source license.

## Registry change

The opentofu registry already has all the providers you are accustomed to, but your state will need to be migrated with:
```sh
tofu init -upgrade`
```

For some providers you might encounter the following warning:
```
- Installed cloudflare/cloudflare v4.23.0. Signature validation was skipped due to the registry not containing GPG keys for this provider
```

This is harmless and will resolve itself when the providers' developers provide the public GPG key used to sign their releases to the opentofu registry. The process is very simple thanks to their GitHub workflow automation.

## Little improvements

- `tofu init` seems significantly faster than `terraform init`.
- You never could interrupt a terraform plan with `C-C`. I am so very glad to see that it is not a problem with opentofu! This really needs more advertising: proper Unix signal handling is like a superpower that is too often ignored by modern software.
- `tofu test` can be used to assert things about your state and your configuration. I did not play with it yet but it opens [a whole new realm of possibilities](https://opentofu.org/docs/cli/commands/test/)!
- `tofu import` can use expressions referencing other values or resources attributes, this is a big deal when handling massive imports!

## Eventline terraform provider

I did the required pull requests on the [opentofu registry](https://github.com/opentofu/registry) to have my [Eventline provider](https://github.com/adyxax/terraform-provider-eventline) all fixed up and ready to rock!

## Conclusion

I hope opentofu really takes off, the little improvements they made already feel like a breath of fresh air. Terraform could be so much more!
