---
title: 'AWS capacity blocks with OpenTofu/terraform'
description: 'Some pitfalls to avoid'
date: '2025-01-04'
tags:
- AWS
- OpenTofu
- terraform
---

## Introduction

AWS capacity blocks for machine learning are a short term GPU instance reservation mechanism. It is somewhat recent and has some rough edges when used via OpenTofu/terraform because of the incomplete documentation. I had to figure out things the hard way a few months ago, here they are.

## EC2 launch template

When you reserve a capacity block, you get a capacity reservation id. You need to feed this id to an EC2 launch template. The twist is that you also need to use a specific instance market option not specified in the AWS provider's documentation for this to work:

``` hcl
resource "aws_launch_template" "main" {
  capacity_reservation_specification {
    capacity_reservation_target {
      capacity_reservation_id = "cr-XXXXXX"
    }
  }
  instance_market_options {
    market_type = "capacity-block"
  }
  instance_type = "p4d.24xlarge"
  # soc2: IMDSv2 for all ec2 instances
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }
  name = "imdsv2-${var.name}"
}
```

## EKS node group

In order to use a capacity block reservation for a kubernetes node group, you need to:
- set a specific capacity type, not specified in the AWS provider's documentation
- use an AMI with GPU support
- disable the kubernetes cluster autoscaler if you are using it (and you should)

``` hcl
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  ami_type      = each.value.gpu ? "AL2_x86_64_GPU" : null
  capacity_type = each.value.capacity_reservation != null ? "CAPACITY_BLOCK" : null
  cluster_name  = aws_eks_cluster.main.name
  labels = {
    adyxax-gpu-node   = each.value.gpu
    adyxax-node-group = each.key
  }
  launch_template {
    name    = aws_launch_template.imdsv2[each.key].name
    version = aws_launch_template.imdsv2[each.key].latest_version
  }
  node_group_name = each.key
  node_role_arn   = aws_iam_role.nodes.arn
  scaling_config {
    desired_size = each.value.scaling.min
    max_size     = each.value.scaling.max
    min_size     = each.value.scaling.min
  }
  subnet_ids = local.subnet_ids
  tags = {
    "k8s.io/cluster-autoscaler/enabled" = each.value.capacity_reservation == null
  }
  update_config {
    max_unavailable = 1
  }
  version = local.versions.aws-eks.nodes-version

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKSCNIPolicy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
  ]
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}
```

## Conclusion

There is a terraform resource to provision the capacity blocks themselves that might be of interest, but I did not attempt to use it seriously. Capacity blocks are never available right when you create them, you need to book them days (sometimes weeks) in advance. Though OpenTofu/terraform has some basic date and time handling functions I could use to work around this, my needs are too sparse to go through the hassle of automating this.
