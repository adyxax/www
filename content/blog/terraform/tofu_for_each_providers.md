---
title: 'Opentofu provider iteration with `for_each`'
description: 'a much anticipated feature'
date: '2025-01-25'
tags:
- AWS
- OpenTofu
---

## Introduction

The latest release of OpenTofu came with a much anticipated feature: provider
iteration with `for_each`!

My code was already no longer compatible with terraform since OpenTofu added the
much needed variable interpolation in provider blocks feature, so I was more
than ready to take the plunge.

## Usage

A good example will be to rewrite the lengthy code from my [Securing AWS default
vpcs]({{< ref "blog/aws/defaults.md" >}}#iterating-through-all-the-default-regions)
article a few months ago. It now looks like:

``` hcl
locals {
  aws_regions = toset([
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-northeast-3",
    "ap-south-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "ca-central-1",
    "eu-central-1",
    "eu-north-1",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
    "sa-east-1",
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
  ])
}

provider "aws" {
  alias = "all"
  default_tags { tags = { "managed-by" = "tofu" } }
  for_each = concat(local.aws_regions)
  profile  = "common"
  region   = each.key
}

module "default" {
  for_each = local.aws_regions
  providers = { aws = aws.all[each.key] }
  source    = "../modules/defaults"
}
```

Note the use of the `concat()` function in the `for_each` definition of the
providers block. This is needed to silence a warning that tells you it is a bad
idea to iterate through your providers using the same expression in provider
definitions and module definitions.

Though I understand the reason (to allow for resources destructions when the
list we are iterating on changes), it is not a bother for me in this case.

## Modules limitations

The main limitation at the moment is the inability to pass down the whole
`aws.all` to a module. This leads to code that repeats itself a bit, but it is
still better than before.

For example, when creating resources for multiple aws accounts, a common pattern
is to have your DNS manged in a specific account (for me it is named `core`)
that you need to pass around. Let's say you have another account named `common`
with for example monitoring stuff and here is how some module invocation can
look like:

``` hcl
module "base" {
  providers = {
    aws          = aws.all["${var.environment}_${var.region}"]
    aws.common   = aws.all["common_us-east-1"]
    aws.core     = aws.all["core_us-east-1"]
  }
  source = "../modules/base"

  ...
}
```

It would be nice to be able to just pass down aws.all, but alas we cannot yet.

## Cardinality limitation

Just be warned that you cannot go too crazy with this mechanism. I tried to
iterate through a cross-product of all AWS regions and a dozen AWS accounts and
it does not go well: OpenTofu slows down to a crawl and it starts taking a dozen
minutes just to instantiate all providers in a folder, before planning any
resources!

This is because providers are instantiated as separate processes that OpenTofu
then talks to. This model does not scale that well (and consumes a fair bit of
memory), as least for the time being.

## Conclusion

I absolutely love this new feature!
