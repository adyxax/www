---
title: Going Social
description: an ActivityPub server experiment (aka joining mastodon with a self hosted instance)
date: 2022-11-11
---

## Introduction

I never saw the appeal of social networks, but increasingly some friends or former colleagues cease to be reachable over IRC or using the only messaging app you had in common. They went social, and if I want to reach them or hear from them other than with an email or a text message I need to get a little involved.

I tried running a personal [pleroma](https://pleroma.social/) instance a few years ago, but stopped because beside not seeing the appeal I did not need it as friends were still available through other means. While advertised as lightweight it still consumed at least 300M of ram which is not light at all in my book. I looked around and did find a lot of alternatives, but only a few appealed to me.

## Choosing one

I was amused by [honk](https://humungus.tedunangst.com/r/honk) which clearly appeals to my sensibilities, but I settled on trying out [ktistec](https://github.com/toddsundsted/ktistec) which seems more writer oriented and is minimalist in other social aspects that I do not want to see like a global timeline. When going to my [social](https://social.adyxax.org) you should see my messages, not whatever I am following. I particularly like this for a personal instance.

It is still a little heavy for me with 100M of ram and might still be a little young under the hood. The repository does not seem to contain unit or integration tests but since the author is using its own software daily that counts as a little testing. The author is also very active on github issues.

## Building

I did not know the crystal language other than by name so I will not be able to contribute much on the coding front. There is a Dockerfile but it did not work out of the box, here is how I built an image:
```sh
git clone https://github.com/toddsundsted/ktistec
cd ktistec
git checkout dist
nvim Dockerfile  # add a step to `RUN shards update` before `shards install`
npm run build
buildah bud -t adyxax/ktistec:2.0.0-3p1
buildah push adyxax/ktistec quay.io/adyxax/ktistec:2.0.0-3p1
```

## Deploy to kubernetes using terraform

Here is the code I wrote to deploy this image to my k3s server.

### DNS
```hcl
resource "cloudflare_record" "social-cname-adyxax-org" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "social"
  value   = "myth.adyxax.org"
  type    = "CNAME"
  proxied = false
}
```

### Namespace
```hcl
resource "kubernetes_namespace" "myth-social" {
  provider = kubernetes.myth
  metadata {
    name = "social"
  }
}
```

### Deployment
```hcl
resource "kubernetes_manifest" "myth-deployment-social" {
  provider = kubernetes.myth
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "name"      = "social"
      "namespace" = kubernetes_namespace.myth-social.id
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "ktistec"
        }
      }
      "strategy" = {
        "type" = "RollingUpdate"
        "rollingUpdate" = {
          "maxSurge"       = 1
          "maxUnavailable" = 0
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "ktistec"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "quay.io/adyxax/ktistec:2.0.0-3p1"
              "livenessProbe" = {
                "httpGet" = {
                  "path" = "/"
                  "port" = 3000
                }
                "initialDelaySeconds" = 5
                "timeoutSeconds"      = 5
              }
              "name" = "ktistec"
              "ports" = [
                {
                  "containerPort" = 3000
                },
              ]
              "readinessProbe" = {
                "httpGet" = {
                  "path" = "/"
                  "port" = 3000
                }
                "initialDelaySeconds" = 5
                "timeoutSeconds"      = 5
              }
              "lifecycle" = {
                "preStop" = {
                  "exec" = {
                    "command" = ["/bin/sh", "-c", "sleep 10"]
                  }
                }
              }
              "volumeMounts" = [
                {
                  "name"      = "ktistec-db"
                  "mountPath" = "/db"
                },
                {
                  "name"      = "ktistec-uploads"
                  "mountPath" = "/uploads"
                }
              ]
            },
          ]
          "terminationGracePeriodSeconds" = 1
          "volumes" = [
            {
              "name" = "ktistec-db"
              "hostPath" = {
                "path" = "/srv/ktistec-db"
                "type" = "Directory"
              }
            },
            {
              "name" = "ktistec-uploads"
              "hostPath" = {
                "path" = "/srv/ktistec-uploads"
                "type" = "Directory"
              }
            }
          ]
        }
      }
    }
  }
}
```

### Service
```hcl
resource "kubernetes_manifest" "myth-service-social" {
  provider = kubernetes.myth
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "social"
      "namespace" = kubernetes_namespace.myth-social.id
    }
    "spec" = {
      "ports" = [
        {
          "port"       = 80
          "protocol"   = "TCP"
          "targetPort" = 3000
        },
      ]
      "selector" = {
        "app" = "ktistec"
      }
      "type" = "ClusterIP"
    }
  }
}
```

### Ingress
```hcl
resource "kubernetes_manifest" "myth-ingress-social" {
  provider = kubernetes.myth
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = "social"
      "namespace" = kubernetes_namespace.myth-social.id
    }
    "spec" = {
      "ingressClassName" = "nginx"
      "rules" = [
        {
          "host" = "social.adyxax.org"
          "http" = {
            "paths" = [
              {
                "path"     = "/"
                "pathType" = "Prefix"
                "backend" = {
                  "service" = {
                    "name" = "social"
                    "port" = {
                      "number" = 80
                    }
                  }
                }
              },
            ]
          }
        },
      ]
      "tls" = [
        {
          "hosts"      = ["social.adyxax.org"]
          "secretName" = "wildcard-adyxax-org"
        },
      ]
    }
  }
}
```

## Conclusion

So far it seems to work as intended, I will see in a few days if I keep ktistec or try to find something else. You can reach me at [adyxax@social.adyxax.org](https://social.adyxax.org/@adyxax) if you want, I would like to hear from you and really try this social experiment.
