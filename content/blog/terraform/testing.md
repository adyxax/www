---
title: 'OpenTofu/Terraform module testing'
description: 'Infrastructure testing is fun!'
date: '2025-04-26'
tags:
- 'aws'
- 'OpenTofu'
- 'terraform'
---

## Introduction

For the last two months, I finally got around to playing with OpenTofu tests.
Infrastructure tests have been teasing me for such a long time! Having mostly
dealt with terraform mono-repos in my career, this was never a big deal because
it is easy to test on just part of an existing environment and therefore never
became a priority.

In the last six months I started building a multi repository system and
thoroughly experimented with testing modules. Here are my thoughts on testing
infrastructure code and a few examples.

## Static checks

Static checks are cheap and useful. Before running terraform tests, [my CI
action](https://git.adyxax.org/adyxax/action-tofu-aws-test) runs the following:

- a `tofu fmt` check to ensure files are properly formatted.
- a `tflint` check to lint the tofu code.
- a `tofu providers lock` to check that the provider locks files all have the
  required platform signatures.

Only after all these steps succeed do I run `tofu test`.

## Testing OpenTofu/Terraform code

The OpenTofu/Terraform [test
command](https://opentofu.org/docs/cli/commands/test/) lets you test a
configuration by creating real infrastructure. This means one or more
instantiations of the module in need of testing, as well as support
infrastructure or resources.

Once the test infrastructure is created, assertions are performed to check that
all the conditions relevant to the module's behavior are met. This involves
checking the module's outputs but one usually also use the outputs of various
data-sources.

Once the test is complete, OpenTofu destroys the resources it created. Know
already that this can fail if the test is not written correctly. All terraform
failures are properly handled, but a common failure case I met was when using
the
[external](https://registry.terraform.io/providers/hashicorp/external/latest/docs)
data-source to run some shell commands and capture their outputs.

## Basic example

The simplest form of tofu test is to create a `main.tftest.hcl` file inside a
module. Here is an example for [a module that creates an AWS IAM
role](https://git.adyxax.org/adyxax/tofu-module-aws-iam-role):

``` hcl
provider "aws" {
  profile = "tests"
  region  = "eu-west-3"
}

run "main" {
  assert {
    condition     = output.arn != null
    error_message = "invalid IAM role ARN"
  }
}

variables {
  name = "tftest-role"
}
```

The module is quite simple: its only purpose being to add a bunch of policy
entries. Testing the correct provisioning of the role would be way more code
than the role itself, so this simple test only does a dummy check to confirm
that all the module's resources instantiate properly.

## More elaborate example

A more complete example that actually tests the correct behavior is what I do
with [a module that creates an AWS IAM
user](https://git.adyxax.org/adyxax/tofu-module-aws-iam-user). Here the test is
to log in with the user's access key and check its identity.

The `main.tftest.hcl` is simpler because it relies on a support module:

``` hcl
provider "aws" {
  profile = "tests"
  region  = "eu-west-3"
}

run "main" {
  assert {
    condition     = data.external.main.result.Arn == local.expected_arn
    error_message = "user ARN mismatch"
  }
  module {
    source = "./test"
  }
}
```

The [support
module](https://git.adyxax.org/adyxax/tofu-module-aws-iam-user/src/branch/main/test)
contains multiple files. The most important one is `main.tf`:

``` hcl
module "main" {
  source = "../"

  name = "tftest-user"
}

data "aws_caller_identity" "current" {}

# tflint-ignore: terraform_unused_declarations
data "external" "main" {
  program = ["${path.module}/test.sh"]

  depends_on = [local_file.aws_config]
}

locals {
  # tflint-ignore: terraform_unused_declarations
  expected_arn = format(
    "arn:aws:iam::%s:user/tftest-user",
    data.aws_caller_identity.current.account_id,
  )
}

resource "local_file" "aws_config" {
  filename        = "${path.module}/aws_config"
  file_permission = "0600"
  content = templatefile("${path.module}/aws_config.tftpl", {
    aws_access_key_id     = module.main.access_key_id
    aws_access_key_secret = module.main.access_key_secret
  })
}
```

The module `main` is the instantiation of the module we are testing. The other
resources are here to allow a login via the AWS CLI in order to test the access.
Note the `tflint-ignore` directives: They are annoying but needed since tflint
does not know how to reconcile that these are used in of `main.tftest.hcl` file.

The test relies on a `aws_config.tftpl` file containing:

``` ini
[default]
aws_access_key_id = ${aws_access_key_id}
aws_secret_access_key = ${aws_access_key_secret}
region = eu-west-3
```

It also relies on this script:

``` shell
#!/usr/bin/env bash
set -euo pipefail

# Wait a bit for the ACCESS KEY to be usable on AWS
sleep 10

export AWS_CONFIG_FILE="${PWD}/test/aws_config"
aws sts get-caller-identity
```

Note that the `external` data-source works with scripts that take JSON input and
JSON output. Luckily this is what the AWS CLI outputs by default, but if you
changed it you will have to tweak this.

## Conclusion

Writing module tests is worthwhile, even if just to validate the proper
instantiation of a module in its most used configurations. I am now validating
that I can properly spawn VPCs, databases, load balancers, generate
certificates... I have never felt more confident in my OpenTofu/Terraform code!

Though I have found that writing the tofu testing code was not the hardest part:
making it all work in CI was. In a next article I will present the test
infrastructure I use to run all this.
