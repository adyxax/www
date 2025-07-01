---
title: 'AWS Identity Center with OpenTofu/Terraform'
description: 'Centralized access control with free sub-accounts'
date: '2025-07-01'
tags:
- 'AWS'
- 'OpenTofu'
- 'Terraform'
---

## Introduction

Many people make mistakes and create immediate tech debt when they get started
with AWS. They rightfully fear that everything is going to be expensive and try
to keep it under control by cramming everything in a single VPC in a single AWS
Account.

This is a big mistake though, because creating multiple AWS accounts (which are
administrative objects isolating everything) is free, and using IAM Identity
Center (successor to AWS Single Sign-On) is a great way to centralize access
control to a multitude of AWS accounts. Separating each environment or project
into its own sub-account is a great way to control security boundaries as well
as keep an eye on costs per AWS sub-account.

I recently took the time to advise a former colleague and friend about getting
started on AWS: here are the resulting notes.

## Bootstrapping AWS Identity Center

Sadly not everything can be automated with OpenTofu/Terraform. The initial
bootstrap must be performed by clicking through the AWS web console:
- Login to your root admin account.
- Select the primary AWS region you will operate in.
- Use the Search Bar to navigate to the IAM Identity Center console.
- Click on the orange `Enable` button to activate Identity Center for your
  organization.
- Configure your Identity Source. You can use the default AWS Identity Center
  directory like I do, or connect an external identity provider.
- Configure the AWS access portal URL as well as your Instance name.
- Configure Multi Factor Authentication.

With these settings out of the way, everything else can be automated with
OpenTofu/Terraform.

## Creating sub-accounts

I use something close to the following input variable in order to manage my
additional AWS accounts:

``` hcl
variable "aws_accounts" {
  description = "AWS accounts to manage."
  nullable    = false
  type = map(object({
    email = string
    ou    = optional(string, null)
  }))
}
```

Here is an example `terraform.tfvars` file provisioning this data structure:

``` hcl
aws_accounts = {
  core = {
    email = "julien.dessaux+aws-core@adyxax.eu"
    ou    = "core-engineering"
  }
  root = {
    email = "julien.dessaux+aws-root@adyxax.eu"
  }
  tests = {
    email = "julien.dessaux+aws-tests@adyxax.eu"
    ou    = "core-engineering"
  }
}
```

You might ask yourselves why I use an `email` attribute that looks pretty easy
to derive consistently from the account name. I do this because creating and
deleting AWS accounts is easy! Though the account names can be reused, the email
address cannot.

After a few years of projects creations and deletions, you will happen to reuse
an account name and will need a different email address. This data structure
helps me remember that and I keep a list of former accounts email addresses in a
comment above this structure.

I manage the Organization Units (OUs) with:
``` hcl
locals {
  ous = toset([for name, info in var.aws_accounts :
    info.ou if info.ou != null
  ])
}

data "aws_organizations_organization" "org" {}

resource "aws_organizations_organizational_unit" "ou" {
  for_each = local.ous

  name      = each.key
  parent_id = data.aws_organizations_organization.org.roots[0].id
}
```

And I manage the AWS accounts using the following configuration:

``` hcl
data "aws_ssoadmin_instances" "root" {}

locals {
  identity_center_arn      = data.aws_ssoadmin_instances.root.arns[0]
  identity_center_store_id = data.aws_ssoadmin_instances.root.identity_store_ids[0]
}

resource "aws_organizations_account" "main" {
  for_each = var.aws_accounts

  close_on_deletion = true
  email             = each.value.email
  name              = each.key
  parent_id         = each.value.ou != null ? aws_organizations_organizational_unit.ou[each.value.ou].id : null

  lifecycle {
    ignore_changes = [role_name]
  }
}
```

The `ignore_changes` lifecycle entry allows importing existing accounts into
this automation, which I do for the root account itself.

## Managing user accounts

I use something close to the following input variable in order to manage
Identity Center user accounts:

``` hcl
variable "users" {
  description = "Users to manage accounts for."
  nullable    = false
  type = map(object({
    admin = object({
      aws = bool
    })
    display_name = optional(string, null)
    email        = string
    family_name  = optional(string, null)
    given_name   = optional(string, null)
  }))
}
```

Here is an example `terraform.tfvars` file provisioning this data structure:

``` hcl
users = {
  julien-dessaux = {
    admin = { aws = true }
    email = "julien.dessaux@adyxax.org"
  }
}
```

The following local variable augments the user accounts by setting defaults for
the optional fields. I use the convention that all usernames follow the
`<firstname>-<lastname>` format and this handles cases where a user's display
name, family name or given name do not exactly fit this scheme:

``` hcl
locals {
  users = { for username, info in var.users :
    username => merge(
      info,
      info.display_name == null ? { display_name = title(replace(username, "-", " ")) } : {},
      info.family_name == null ? { family_name = split(" ", title(replace(username, "-", " ")))[1] } : {},
      info.given_name == null ? { given_name = split(" ", title(replace(username, "-", " ")))[0] } : {},
    )
  }
}
```

Creating the actual IAM Identity Center user is done with:

``` hcl
resource "aws_identitystore_user" "main" {
  for_each = local.users

  display_name = each.value.display_name
  emails {
    primary = true
    value   = each.value.email
  }
  identity_store_id = local.identity_center_store_id
  name {
    family_name = each.value.family_name
    given_name  = each.value.given_name
  }
  user_name = each.key
}
```

Now that we have users provisioned, let's grant them permissions on our
infrastructure.

## Granting admin access

An IAM Identity Center group can be created with:

``` hcl
resource "aws_identitystore_group" "admin" {
  display_name      = "admin"
  identity_store_id = local.identity_center_store_id
}
```

Assigning members to this group is a matter of:

``` hcl
resource "aws_identitystore_group_membership" "admin" {
  for_each = { for username, info in var.users :
    username => info if info.admin.aws
  }

  group_id          = aws_identitystore_group.admin.group_id
  identity_store_id = local.identity_center_store_id
  member_id         = aws_identitystore_user.main[each.key].user_id
}
```

Permissions are granted through permission sets of attached policies:

``` hcl
resource "aws_ssoadmin_permission_set" "admin" {
  instance_arn     = local.identity_center_arn
  name             = "admin"
  session_duration = "PT12H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = local.identity_center_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

resource "aws_ssoadmin_account_assignment" "admin" {
  for_each = aws_organizations_account.main

  instance_arn       = local.identity_center_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = each.value.id
  target_type        = "AWS_ACCOUNT"
}
```

## Generating your AWS CLI configuration file

I rely on the following OpenTofu/Terraform template to generate my
`~/.aws/config` file:

``` hcl
[default]
region = eu-west-3
sso_session = adyxax

[sso-session adyxax]
sso_start_url = https://adyxax.awsapps.com/start
sso_region = eu-west-3
sso_registration_scopes = sso:account:access

%{~for name, id in accounts}
[profile ${name}]
sso_account_id = ${id}
sso_role_name = admin
sso_session = adyxax
%{endfor~}
```

Using this template, I output my configuration with:

``` hcl
output "aws_config" {
  value = templatefile("./aws_config", {
    accounts = { for name, info in aws_organizations_account.main :
      name => info.id
    }
  })
}
```

Each morning, I log in with:

``` shell
aws sso login
```

To access a specific account, I use the `--profile` CLI flag:

``` shell
aws --profile core s3 ls
```

## Conclusion

Starting your AWS journey with multiple accounts and centralized access
management as shown in this article will help you avoid quite a few pitfalls.
Though there are a few clicks to perform for the initial setup, everything
important can be automated quite well.

I recommend everyone to make the effort to commit to this approach from the
beginning in order to have a scalable, secure and cost-effective AWS environment
at your disposal.
