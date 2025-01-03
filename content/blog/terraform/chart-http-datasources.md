---
title: Manage helm charts extras with OpenTofu
description: a use case for the http datasource
date: 2024-04-25
tags:
- AWS
- OpenTofu
- terraform
---

## Introduction

When managing helm charts with OpenTofu (terraform), you often have to hard code correlated settings for versioning (like app version and chart version). Sometimes it goes even further and you need to fetch a policy or a manifest with some CRDs that the chart will depend on.

Here is an example of how to manage that with OpenTofu and an http datasource for the AWS load balancer controller.

## A word about the AWS load balancer controller

When looking at the AWS load balancer controller helm chart in [its GitHub repository](https://github.com/aws/eks-charts/tree/master), you can see that the eks chart version is tagged `0.0.168`. But this is not the chart version you can install with helm as you can see when exploring [the repository](https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/Chart.yaml): it is `1.7.2`, and it installs the `2.7.2` version of the component packaged inside.

To make it work, you will need to create an aws role and attach [this policy](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json) to it.

One way that I have witnessed is to specify the different versions in the terraform code and to commit the file along with your module. This burdens your future self with some complexity because you would miss on changes during updates.

## Using the http datasource

Here is how to use the datasource from the `http` terraform provider to do some magic:
``` hcl
data "http" "aws_load_balancer_controller_chart_yaml" {
  url = "https://raw.githubusercontent.com/aws/eks-charts/v${var.chart_version}/stable/aws-load-balancer-controller/Chart.yaml"
}
```

With this we decode the yaml and get the information we need:
``` hcl
locals {
  app_version   = local.chart_yaml.appVersion
  chart_version = local.chart_yaml.version
  chart_yaml    = yamldecode(data.http.aws_load_balancer_controller_chart_yaml.response_body)
}
```

The last important thing is to fetch the policy that matches the component packaged by this helm chart:

``` hcl
data "http" "aws_load_balancer_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${local.app_version}/docs/install/iam_policy.json"
}
```

## Remaining code in my module

Here are the two variable that compose this module's interface in a `main.tf` file:
``` hcl
# References:
#
# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
# https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

variable "chart_version" {
  default     = "0.0.168" # controller version 2.7.2
  description = "eks chart version from https://github.com/aws/eks-charts"
  type        = string
}
variable "cluster_name" {
  type = string
}
```

There are a few more local data needed to make it all work
``` hcl
data "aws_eks_cluster" "main" {
  name = var.cluster_name
}
data "aws_iam_openid_connect_provider" "main" {
  url = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}
data "aws_region" "current" {}
locals {
  namespace            = "kube-system"
  oidc_issuer          = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
  oidc_provider_arn    = data.aws_iam_openid_connect_provider.main.arn
  service_account_name = "load-balancer-controller"
}
```

The aws IAM code looks like this:
``` hcl
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${replace(local.oidc_issuer, "https://", "")}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:${local.namespace}:${local.service_account_name}"]
      variable = "${replace(local.oidc_issuer, "https://", "")}:sub"
    }
    effect = "Allow"
    principals {
      identifiers = [local.oidc_provider_arn]
      type        = "Federated"
    }
  }
}
resource "aws_iam_role" "controller" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = "load-balancer-controller-${var.cluster_name}"
}

resource "aws_iam_policy" "controller" {
  name   = "load-balancer-controller-${var.cluster_name}"
  policy = data.http.aws_load_balancer_controller_policy.response_body
}
resource "aws_iam_role_policy_attachment" "controller" {
  policy_arn = aws_iam_policy.controller.arn
  role       = aws_iam_role.controller.name
}
```

Finally here is the helm chart resource:
``` hcl
# Source:
# https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller
resource "helm_release" "controller" {
  chart      = "aws-load-balancer-controller"
  name       = "load-balancer-controller"
  namespace  = local.namespace
  repository = "https://aws.github.io/eks-charts"
  values = [yamlencode({
    "clusterName"                                               = var.cluster_name
    "region"                                                    = data.aws_region.current.name
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.controller.arn
    "serviceAccount.name"                                       = local.service_account_name
    "vpcId"                                                     = data.aws_eks_cluster.main.vpc_config.0.vpc_id
  })]
  version = local.chart_version
}
```

## Conclusion

The http terraform provider [does not look like much](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) but it can be very useful to prevent the burden of maintaining correlated settings.
