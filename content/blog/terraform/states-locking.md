---
title: OpenTofu/Terraform state locking with S3 object locking
description: Relying on DynamoDB is no longer necessary
date: 2025-10-20
tags:
- AWS
- OpenTofu
- terraform
---

## Introduction

Today's AWS outage is a good time to remind sysadmins that AWS DynamoDB is no
longer required to handle state file locking when storing state files on AWS S3.

Since last year, the S3 state backend has supported state locking via S3 object
locks. This locking method is simpler, faster and removes a dependency on an AWS
service that we no longer need. DynamoDB was the default state backend locking
mechanism for many years and has served us well, but today's AWS outage is a
good time to move on if you have not already done so.

## Migration steps

### Make sure bucket versioning is enabled

I cannot imaging why anyone would store OpenTofu/Terraform state files without
versioning, but if for some reason you did not already then know that versioning
is a requirement for activating S3 object locks. A simple configuration like the
following is enough:

``` hcl
resource "aws_s3_bucket_versioning" "tofu_states" {
  bucket = aws_s3_bucket.tofu_states.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tofu_states" {
  bucket = aws_s3_bucket.tofu_states.id
  rule {
    filter {}
    id = "main"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    noncurrent_version_transition {
      noncurrent_days = 2
      storage_class   = "STANDARD_IA"
    }
    noncurrent_version_transition {
      noncurrent_days = 14
      storage_class   = "GLACIER"
    }
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket_versioning.tofu_states]
}
```

### Activating S3 object locks

The first step is to activate object locks on the OpenTofu/Terraform states S3
bucket. Sadly, simply adding the attribute to the `aws_s3_bucket` resource won't
be sufficient as OpenTofu/Terraform will then try to recreate the bucket.

``` shell
aws --profile core \
    s3api put-object-lock-configuration \
    --bucket adyxax-tofu-states \
    --object-lock-configuration='{"ObjectLockEnabled":"Enabled"}'
```

After typing this AWS CLI command, you will be able to update your
`aws_s3_bucket` resource. Applying the changes will refresh the state and
confirm the change is correctly implemented.

``` hcl
resource "aws_s3_bucket" "tofu_states" {
  bucket              = "adyxax-tofu-states"
  object_lock_enabled = true
}
```

### Reconfiguring your terraform backend

Update your OpenTofu/Terraform S3 backend configuration blocks to add the
`use_lockfile = true` attribute:

``` hcl
terraform {
  backend "s3" {
    bucket         = "adyxax-tofu-states"
    dynamodb_table = "tofu-states"
    key            = "repositories/${local.name}"
    profile        = "core"
    region         = "eu-west-3"
    use_lockfile   = true
  }
}
```

By setting both `dynamodb_table` and `use_lockfile`, applying changes will lock
both systems at the same time. This is important if you need to roll out your
change gradually as to not disrupt your colleagues work or your CI jobs.

If you can afford the disruption, it will be faster to just delete the DynamoDB
state locks table and remove the `dynamodb_table` attribute.

As with all backend configuration changes, you will need to init your
OpenTofu/Terraform folders again:

``` shell
tofu init -reconfigure
```

Once the change has been applied in all your OpenTofu/Terraform folders and
repositories, all your pull requests merged or rebased and you are sure
everybody and everything is on the new locking system, you can safely remove the
`dynamodb_table` from your backend configuration blocks:

``` hcl
terraform {
  backend "s3" {
    bucket       = "adyxax-tofu-states"
    key          = "repositories/${local.name}"
    profile      = "core"
    region       = "eu-west-3"
    use_lockfile = true
  }
```

You will need to `init -reconfigure` your folders again.

### Deleting the DynamoDB state locks table

The last step is to destroy the DynamoDB table that used to hold your locks. If
you have deletion protection activated, remove it with:

``` shell
aws --profile core --region eu-west-3 \
    dynamodb update-table \
    --table-name tofu-states \
    --no-deletion-protection-enabled
```

With this done, destroy your DynamoDB table and remove any IAM policies
controlling DynamoDB access to the table and any cloudwatch alerts used to
monitor it. I personally do this with a `tofu apply` because everything is
managed from there.

## Conclusion

S3 object locks have served me well since they were made available as a backend
locking mechanism. If you are still relying on DynamoDB, now is a good time to
migrate away from this service.
