---
title: "A Forgejo action for OpenTofu module testing on AWS"
date: 2025-09-30
description: "A corner stone of my CI"
tags:
  - AWS
  - CI
  - Forgejo
  - OpenTofu
  - Terraform
---

## Introduction

I have been using a Forgejo action (compatible with GitHub actions) for testing
my OpenTofu/Terraform modules on AWS. I planned to blog this earlier, but since
it worked without quirks I completely forgot to publish it.

## Usage example

The action relies on having an AWS IAM access key provisioned in your CI's
secrets. An astute reader will notice I am naming the secret
`AWS_ACCESS_KEY_SECRET` instead of the standard `AWS_SECRET_ACCESS_KEY`, mind
this if trying to reproduce in your own environment:

``` yaml
- uses: "https://git.adyxax.org/adyxax/action-tofu-aws-test@2.0.0"
  with:
    aws-access-key-id: "${{ vars.AWS_ACCESS_KEY_ID }}"
    aws-access-key-secret: "${{ secrets.AWS_ACCESS_KEY_SECRET }}"
```

## Action steps

This action initializes the AWS credentials, then runs formatting and linting
checks as well as tofu tests on the repository of an OpenTofu/Terraform module.

### Boilerplate

Forgejo actions need some light boilerplate to define how they are to be used:

``` yaml
name: "tofu-aws-test"
description: "Test a tofu module on AWS."

inputs:
  aws-access-key-id:
    description: "AWS access key id."
    required: true
  aws-access-key-secret:
    description: "AWS access key secret."
    required: true

runs:
  using: "composite"
  steps:
```

### Formatting and linting

These are two simple steps. The only caveat is that I need to unset the
`GITHUB_TOKEN` environment variable before running `tflint`. This is because
Forgejo strives for compatibility with GitHub actions, but sadly `tflint` will
try to use said token for cloning its plugins. Since the token is generated on
my Forgejo instance, it is only valid there and not on GitHub. This would cause
the step to fail.

``` yaml
    - name: "fmt"
      shell: "bash"
      run: |
        tofu fmt -check -recursive
    - name: "lint"
      shell: "bash"
      run: |
        unset GITHUB_TOKEN
        tflint --init
        tflint --recursive
```

### AWS credentials initialization

If you followed my past articles you will know that I am using multiple AWS
accounts to separate everything. I strive to have all my test resources created
in a `tests` AWS account, but some things like DNS records will occasionally
require access to my `core` AWS account where DNS zones are provisioned.

I am using AWS policies to tightly control what tests can provision in this
`core` account, but I will not detail it in this article.

``` yaml
    - name: "configure AWS profiles"
      shell: "bash"
      run: |
        ROLE_NAME="repository_${GITHUB_REPOSITORY/\//_}"
        cat >aws_config <<EOF
        [profile core]
        role_arn = arn:aws:iam::123456789012:role/${ROLE_NAME}
        source_profile = root

        [profile root]
        aws_access_key_id = ${{ inputs.aws-access-key-id }}
        aws_secret_access_key = ${{ inputs.aws-access-key-secret }}
        region = eu-west-3

        [profile tests]
        role_arn = arn:aws:iam::345678901234:role/${ROLE_NAME}
        source_profile = root
        EOF
```

One should of course use their own AWS account IDs here!

### OpenTofu/Terraform lock files

It is important to make sure your lock files match the provider versions pinned
in your configuration. This step does exactly this!

This step has some code to recurse in subfolders because I love to use a pattern
where some OpenTofu code specific to a repository lives alongside a module or
some other code:

``` yaml
    - name: "check tofu providers lock files"
      shell: "bash"
      run: |
        unset GITHUB_TOKEN
        export AWS_CONFIG_FILE="$(pwd)/aws_config"
        shopt -s globstar nullglob
        for lockfile in **/.terraform.lock.hcl; do
          (cd "$(dirname "$lockfile")"; tofu init; tofu providers lock -platform=linux_amd64)
        done
        git diff --exit-code
```

### OpenTofu/Terraform tests

I am running module tests with:

``` yaml
    - name: "tofu test"
      shell: "bash"
      run: |
        export AWS_CONFIG_FILE="$(pwd)/aws_config"
        tofu init
        tofu test
```

### Cleanup

 We clean up to be sure that the next steps in the workflow are not affected:

``` yaml
    - name: "clean"
      shell: "bash"
      run: |
        rm aws_config
```

## Conclusion

Here is [the link to the
repository](https://git.adyxax.org/adyxax/action-tofu-aws-test). Writing
composite actions like this one is a good exercise and can be used to keep your
workflows tidy and DRY!
