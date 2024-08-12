---
title: Managing AWS secrets
description: with the CLI and with terraform/opentofu
date: 2024-08-13
tags:
- aws
- opentofu
- terraform
---

## Introduction

Managing secrets in AWS is not an everyday task that allows me to naturally remember the specifics when I need them, especially the `--name` and `--secret-id` CLI inconsistency. I found I was lacking some simple notes that would prevent me from having to search the web in the future, here they are.

## CLI

### Creating secrets

From a simple string:

``` shell
aws --profile common secretsmanager create-secret \
    --name test-string \
    --secret-string 'test'
```

From a text file:

``` shell
aws --profile common secretsmanager create-secret \
    --name test-text \
    --secret-string "$(cat ~/Downloads/adyxax.2024-07-31.private-key.pem)"
```

For binary file we `base64` encode the data:

``` shell
aws --profile common secretsmanager create-secret \
    --name test-binary \
    --secret-binary "$(cat ~/Downloads/some-blob|base64)"
```

### Updating secrets

Beware that all the other aws secretsmanager commands use the `--secret-id` flag instead of the `--name` we needed when creating the secret.

Update a secret string with:

``` shell
aws --profile common secretsmanager update-secret \
    --secret-id test-string \
    --secret-string 'test'
```

### Reading secrets

Listing:

``` shell
aws --profile common secretsmanager list-secrets | jq -r '[.SecretList[].Name]'
```

Getting a secret value:

``` shell
aws --profile common secretsmanager get-secret-value --secret-id test-string
```

### Deleting secrets

``` shell
aws --profile common secretsmanager delete-secret --secret-id test-string
```

## Terraform

### Resource

Secret string:

``` hcl
resource "random_password" "main" {
  length  = 64
  special = false
  lifecycle {
    ignore_changes = [special]
  }
}

resource "aws_secretsmanager_secret" "main" {
  name = "grafana-admin-password"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = random_password.main.result
}
```

Secret binary:

``` hcl
resource "random_bytes" "main" {
  length = 32
}

resource "aws_secretsmanager_secret" "main" {
  name = "data-encryption-key"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_binary = random_bytes.main.base64
}
```

### Datasource

``` hcl
data "aws_secretsmanager_secret_version" "main" {
  secret_id = "test"
}
```

Using the datasource differs if it contains a `secret_string` or a `secret_binary`. In most cases you will know your secret data therefore know which one to use. If for some reason you do not, this might be one of the rare legitimate use cases for the [try function](https://developer.hashicorp.com/terraform/language/functions/try):

``` hcl
try(
  data.aws_secretsmanager_secret_version.main.secret_binary,
  data.aws_secretsmanager_secret_version.main.secret_string,
)
```

## Conclusion

Once upon a time I wrote many small and short articles like this one but for some reason stopped. I will try to take on this habit again.
