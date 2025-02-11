---
title: 'Validating input files with OpenTofu/Terraform'
description: 'Works with JSON or YAML files'
date: '2025-02-11'
tags:
- OpenTofu
- Terraform
---

## Introduction

I am used to building small abstraction layers over some OpenTofu/Terraform code
via YAML input files. It would be too big an ask to require people (usually
developers) unfamiliar with infrastructure automation to understand the
intricacies of HCL, but filling up YAML (or JSON) files is no problem at all.

In this article I will explain how I perform some measure of validation on these
input files, as well as handle default values.

## Input file validation

I am using two nested modules to abstract this validation away. I name the top
module `input` and its job is to read and decode the input files, then call the
nested `validation` module with them.

### Input module

A simplified version of this `input` module contains the following:

``` hcl
output "data" {
  description = "The output of the validation module."
  value       = module.validation
}

locals {
  input_path = "${path.module}/../../../inputs"
}

module "validation" {
  source = "./validation/"

  teams = yamldecode(file("${local.input_path}/teams.yaml"))
  users = yamldecode(file("${local.input_path}/users.yaml"))
}
```

There is a single output to expose the validated data. The `input_path` should
obviously point to where your `inputs` data lives.

### The validation submodule

The `validation` module does the heavy lifting of validating the input, handling
default values and mangling data in necessary ways. Here is a simplified
example:

``` hcl
output "aws_iam_users" {
  description = "The aws IAM users data."
  value = { for user, info in var.users :
    user => info if info.admin.aws
  }
}

output "users" {
  description = "The users data."
  value       = var.users
}

variable "users" {
  description = "The yaml decoded contents of the users input file."
  nullable    = false
  type = map(object({
    admin = optional(object({
      aws    = optional(bool, false)
      github = optional(bool, false)
    }), {})
    email  = string
    github = optional(string, null)
  }))
  validation {
    condition = alltrue([for _, info in var.users :
      endswith(info.email, "@adyxax.org")
    ])
    error_message = "A user's email must be for the @adyxax.org domain."
  }
}
```

Here I have two outputs: one that mangles the input data a bit to filter AWS
admin users, and another that simply returns the input data augmented by the
default values. I added a validation block that checks that every users' email
address is on the proper domain.

### Usage

Using this input module is as simple as:

``` hcl
module "input" {
  source = "../modules/input/"
}
```

With this, you can then do something with `module.input.data.users` or
`module.input.data.aws_iam_users`. A common debugging step can be to run
OpenTofu or Terraform with the `console` command and inspect the resulting input
data.

## Limitations

The main limitation of this validation system is that invalid (or misspelled)
keys in the original input file are simply ignored by OpenTofu/Terraform. I did
not find a way around it with just terraform which is frustrating!

A solution to this particular need that relies on outside tooling is to perform
JSON schema or YAML schema validation. This solves the problem and runs nicely
in a CI environment.

## Conclusion

This pattern is really useful, use it without moderation!
