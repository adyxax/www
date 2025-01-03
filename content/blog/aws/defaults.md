---
title: Securing AWS default VPCs
description: With terraform/OpenTofu
date: 2024-09-10
tags:
- AWS
- OpenTofu
- terraform
---

## Introduction

AWS offers some network conveniences in the form of a default VPC, default security group (allowing access to the internet) and default routing table. These exist in all AWS regions your accounts have access to, even if never plan to deploy anything there. And yes most AWS regions cannot be disabled entirely, only the most recent ones can be.

I feel the need to clean up these resources in order to prevent any misuse. Most people do not understand networking and some could inadvertently spawn instances with public IP addresses. By making the default VPC inoperative, these people need to come to someone more knowledgeable before they do anything foolish.

## Module

The special default variants of the following AWS terraform resources are quirky: defining them does not create anything but automatically import the built-in aws resources and then edit their attributes to match your configuration. Furthermore, destroying these resources would only remove them from your state.

``` hcl
resource "aws_default_vpc" "default" {
  tags = { Name = "default" }
}

resource "aws_default_security_group" "default" {
  ingress = []
  egress  = []
  tags    = { Name = "default" }
  vpc_id  = aws_default_vpc.default.id
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_default_vpc.default.default_route_table_id
  route                  = []
  tags                   = { Name = "default - empty" }
}
```

The key here (and initial motivation for this article) is the `ingress = []` expression syntax (or `egress` or `route`): while these attributes are normally block attributes, you can also use them in a `= []` expression in order to express that you want to enforce the resource not having any ingress, egress or route rules. Defining the resources without any block rules would just leave these attributes untouched.

## Iterating through all the default regions

As I said, most AWS regions cannot be disabled entirely, only the most recent ones can be. It is currently not possible to instanciate terraform providers on the fly, but thankfully it is coming in a future OpenTofu release! In the meantime, we need to do these kinds of horrors:

``` hcl
provider "aws" {
  alias   = "ap-northeast-1"
  profile = var.environment
  region  = "ap-northeast-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "ap-northeast-2"
  profile = var.environment
  region  = "ap-northeast-2"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "ap-northeast-3"
  profile = var.environment
  region  = "ap-northeast-3"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "ap-south-1"
  profile = var.environment
  region  = "ap-south-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "ap-southeast-1"
  profile = var.environment
  region  = "ap-southeast-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "ap-southeast-2"
  profile = var.environment
  region  = "ap-southeast-2"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "ca-central-1"
  profile = var.environment
  region  = "ca-central-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "eu-central-1"
  profile = var.environment
  region  = "eu-central-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "eu-north-1"
  profile = var.environment
  region  = "eu-north-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "eu-west-1"
  profile = var.environment
  region  = "eu-west-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "eu-west-2"
  profile = var.environment
  region  = "eu-west-2"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "eu-west-3"
  profile = var.environment
  region  = "eu-west-3"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "sa-east-1"
  profile = var.environment
  region  = "sa-east-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "us-east-1"
  profile = var.environment
  region  = "us-east-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "us-east-2"
  profile = var.environment
  region  = "us-east-2"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "us-west-1"
  profile = var.environment
  region  = "us-west-1"
  default_tags { tags = { "managed-by" = "tofu" } }
}

provider "aws" {
  alias   = "us-west-2"
  profile = var.environment
  region  = "us-west-2"
  default_tags { tags = { "managed-by" = "tofu" } }
}

module "ap-northeast-1" {
  providers = { aws = aws.ap-northeast-1 }
  source    = "../modules/defaults"
}

module "ap-northeast-2" {
  providers = { aws = aws.ap-northeast-2 }
  source    = "../modules/defaults"
}

module "ap-northeast-3" {
  providers = { aws = aws.ap-northeast-3 }
  source    = "../modules/defaults"
}

module "ap-south-1" {
  providers = { aws = aws.ap-south-1 }
  source    = "../modules/defaults"
}

module "ap-southeast-1" {
  providers = { aws = aws.ap-southeast-1 }
  source    = "../modules/defaults"
}

module "ap-southeast-2" {
  providers = { aws = aws.ap-southeast-2 }
  source    = "../modules/defaults"
}

module "ca-central-1" {
  providers = { aws = aws.ca-central-1 }
  source    = "../modules/defaults"
}

module "eu-central-1" {
  providers = { aws = aws.eu-central-1 }
  source    = "../modules/defaults"
}

module "eu-north-1" {
  providers = { aws = aws.eu-north-1 }
  source    = "../modules/defaults"
}

module "eu-west-1" {
  providers = { aws = aws.eu-west-1 }
  source    = "../modules/defaults"
}

module "eu-west-2" {
  providers = { aws = aws.eu-west-2 }
  source    = "../modules/defaults"
}

module "eu-west-3" {
  providers = { aws = aws.eu-west-3 }
  source    = "../modules/defaults"
}

module "sa-east-1" {
  providers = { aws = aws.sa-east-1 }
  source    = "../modules/defaults"
}

module "us-east-1" {
  providers = { aws = aws.us-east-1 }
  source    = "../modules/defaults"
}

module "us-east-2" {
  providers = { aws = aws.us-east-2 }
  source    = "../modules/defaults"
}

module "us-west-1" {
  providers = { aws = aws.us-west-1 }
  source    = "../modules/defaults"
}

module "us-west-2" {
  providers = { aws = aws.us-west-2 }
  source    = "../modules/defaults"
}
```

## Conclusion

Terraform is absolutely quirky at times, but it is not its fault here: the AWS provider and their magical default resources are.
