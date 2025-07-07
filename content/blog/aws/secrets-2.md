---
title: Enforcing AWS Secret version with OpenTofu/Terraform
description: A common pitfall
date: 2025-07-08
tags:
- AWS
- OpenTofu
- Terraform
---

## Introduction

Managing secrets in AWS is a common task. It is therefore surprising that the
default `aws_secretsmanager_secret_version` usage does not properly enforce a
secret value.

At first glance, it appears to enforce secret versions properly because updating
the secret's value results in an updated AWS secret version accordingly.
Furthermore, if the secret is deleted then OpenTofu/Terraform will recreate it
with the proper value as well! However, the unexpected behavior occurs when the
value of the secret is manually changed: in that case, OpenTofu/Terraform will
do nothing to reconcile or restore the value.

## Properly enforcing a secret value

To solve this issue, the stage of the managed secret version needs to be
enforced. Given the following basic resources that generate a random password
and a secret:

``` hcl
resource "random_password" "main" {
  length = 64
}

resource "aws_secretsmanager_secret" "main" {
  name = "secret"
}
```

A secret version stage can be enforced with:

``` hcl
resource "aws_secretsmanager_secret_version" "main" {
  secret_id      = aws_secretsmanager_secret.main.id
  secret_string  = random_password.main.result
  version_stages = ["AWSCURRENT"]
}
```

The important attribute in the context of this article is `version_stages`.
Though optional and not mentioned in [the example usages of the resource's
documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version),
it is what properly enforces this secret's value as the current version.

## Conclusion

I am in awe that I managed to go on for so many years without encountering this
particular issue! Systematically specifying the `version_stages` attribute in
all secret version resources is a boilerplate that I could have lived without,
but necessary to ensure reliability. I find solace knowing that any manual
changes to a secret value performed outside of OpenTofu/Terraform are now
properly detected and corrected.
