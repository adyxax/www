---
title: 'Deploy the Nvidia device plugin for kubernetes'
description: 'Using OpenTofu/terraform'
date: '2025-01-19'
tags:
- AWS
- kubernetes
- OpenTofu
- terraform
---

## Introduction

The Nvidia device plugin for kubernetes is a daemonset that allows you to exploit GPUs in a kubernetes cluster. In particular, it allows you to request a number of GPUs from the pods' spec.

This article presents the device plugin's installation and usage on AWS EKS.

## Installation

The main pre-requisite is that your nodes have the nvidia drivers and container toolkit installed. On EKS, this means using an `AL2_x86_64_GPU` AMI.

The device plugin daemonset can be setup using the following OpenTofu/terraform code, which is adapted from https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/master/deployments/static/nvidia-device-plugin.yml :

 ``` hcl
resource "kubernetes_daemon_set_v1" "nvidia-k8s-device-plugin" {
  metadata {
    name      = "nvidia-device-plugin"
    namespace = "kube-system"
  }
  spec {
    selector {
      match_labels = {
        name = "nvidia-device-plugin"
      }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        annotations = {
          "adyxax.org/promtail" = true
        }
        labels = {
          name = "nvidia-device-plugin"
        }
      }
      spec {
        container {
          image = format(
            "%s:%s",
            local.versions["nvidia-k8s-device-plugin"].image,
            local.versions["nvidia-k8s-device-plugin"].tag,
          )
          name = "nvidia-device-plugin-ctr"
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          volume_mount {
            mount_path = "/var/lib/kubelet/device-plugins"
            name       = "data"
          }
        }
        node_selector = {
          adyxax-gpu-node = true
        }
        priority_class_name = "system-node-critical"
        toleration {
          effect   = "NoSchedule"
          key      = "nvidia.com/gpu"
          operator = "Exists"
        }
        volume {
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
          name = "data"
        }
      }
    }
  }
  wait_for_rollout = false
}
```

I add a `node_selector` to only provision the device plugin on nodes that need it, since I am also running non GPU nodes in my clusters.

## Usage

To grant GPU access to a pod, you set a resources limit and request. It is important that you set both since GPUs are a non overcommittable resource
on kubernetes. When you request some you also need to set an equal limit.

``` yaml
resources:
  limits:
    nvidia.com/gpu: 8
  requests:
    nvidia.com/gpu: 8
```

Note that all GPUs are detected as equal by the device plugin. If your cluster mixes nodes with different GPU hardware configurations, you will need to use taints and tolerations to make sure your workloads are assigned correctly.

## Conclusion

It works well as is. I have not played with neither GPU time slicing nor MPS.
