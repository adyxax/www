---
title: "Installation"
description: Installation notes of vaultwarden on k3s
tags:
- k3s
- kubernetes
- postgresql
- vaultwarden
---

## Introduction

Please refer to [the official website](https://pass.app/) documentation for an up to date installation guide. This page only lists what I had to do at the time to setup pass and adapt it to my particular setup. I updated these instructions after migrating from a traditional hosting to kubernetes.

## Preparing the postgresql database

I have a postgresql running in its own namespace from bitnami images. To provision the pass database I :
```sh
export POSTGRES_PASSWORD=$(k get secret -n postgresql postgresql-secrets -o jsonpath="{.data.postgresql-password}"|
    base64 --decode)
k run client --rm -ti -n postgresql --image docker.io/bitnami/postgresql:13.4.0-debian-10-r52 \
    --env="PGPASSWORD=$POSTGRES_PASSWORD" --command --  psql --host postgresql -U postgres
CREATE ROLE pass WITH LOGIN PASSWORD 'secret';
CREATE DATABASE pass WITH OWNER pass TEMPLATE template0 ENCODING UTF8 LC_COLLATE
    'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
\c pass
create extension hstore;
```

Optionally import a dump of the database by running in another shell :
```sh
k -n postgresql cp pass.sql-20211005 client:/tmp/
```

Then in the psql shell :
```sh
\c pass
\i /tmp/pass.sql-20211005
```

## Kubernetes manifests in terraform

This app is part of an experiment of mine to migrate stuff from traditional hosting to kubernetes. I first wrote manifests by hand then imported them with terraform. I do not like it and find it too complex/overkill but that is managed this way for now.

### DNS CNAME

Since all configuration regarding this application is in terraform, so is the dns :
```hcl
resource "cloudflare_record" "pass-cname" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "pass"
  value   = "myth.adyxax.org"
  type    = "CNAME"
  proxied = false
}
```

### Namespace

The basic terraform object works for simple things so here it is :
```hcl
resource "kubernetes_namespace" "myth-pass" {
  provider = kubernetes.myth
  metadata {
    name = "pass"
  }
}
```

### Secret

Here is the kubernetes secret that tells pass how to connect the database. The password comes from `terraform.tfvars`, you might need to update the service url with the format `<svc>.<namespace>.svc.cluster.local` :
```hcl
resource "kubernetes_secret" "myth-pass-secrets" {
  provider = kubernetes.myth
  metadata {
    name      = "pass-secrets"
    namespace = kubernetes_namespace.myth-pass.id
  }
  data = {
    ADMIN_PASSWORD = var.pass-admin-password
    DATABASE_URL   = join("", [ "postgres://pass:${var.pass-postgres-password}",
        "@postgresql.postgresql.svc.cluster.local/pass?sslmode=disable"])
  }
  type = "Opaque"
}
```

### Deployment

I could not write the deployment with the `kubernetes_deployment` terraform ressource, so it is a row manifest which imports a yaml syntax in hcl. It is horrible to look at but works. Change the image tag to the latest stable version of pass before deploying :
```hcl
resource "kubernetes_manifest" "myth-deployment-pass" {
  provider = kubernetes.myth
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "name"      = "pass"
      "namespace" = kubernetes_namespace.myth-pass.id
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "pass"
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
            "app" = "pass"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "DATABASE_URL"
                  "valueFrom" = {
                    "secretKeyRef" = {
                      "key"  = "DATABASE_URL"
                      "name" = "pass-secrets"
                    }
                  }
                },
                {
                  "name"  = "RUN_MIGRATIONS"
                  "value" = "1"
                },
                {
                  "name"  = "ADMIN_USERNAME"
                  "value" = "admin"
                },
                {
                  "name" = "ADMIN_PASSWORD"
                  "valueFrom" = {
                    "secretKeyRef" = {
                      "key"  = "ADMIN_PASSWORD"
                      "name" = "pass-secrets"
                    }
                  }
                },
              ]
              "image" = "vaultwarden/server:1.23.0"
              "livenessProbe" = {
                "httpGet" = {
                  "path" = "/"
                  "port" = 8080
                }
                "initialDelaySeconds" = 5
                "timeoutSeconds"      = 5
              }
              "name" = "pass"
              "ports" = [
                {
                  "containerPort" = 8080
                },
              ]
              "readinessProbe" = {
                "httpGet" = {
                  "path" = "/"
                  "port" = 8080
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
            },
          ]
          "terminationGracePeriodSeconds" = 1
        }
      }
    }
  }
}
```

### Service

```hcl
resource "kubernetes_manifest" "myth-service-pass" {
  provider = kubernetes.myth
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "pass"
      "namespace" = kubernetes_namespace.myth-pass.id
    }
    "spec" = {
      "ports" = [
        {
          "port"       = 80
          "protocol"   = "TCP"
          "targetPort" = 8080
        },
      ]
      "selector" = {
        "app" = "pass"
      }
      "type" = "ClusterIP"
    }
  }
}
```

### Ingress

```hcl
resource "kubernetes_manifest" "myth-ingress-pass" {
  provider = kubernetes.myth
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = "pass"
      "namespace" = kubernetes_namespace.myth-pass.id
    }
    "spec" = {
      "ingressClassName" = "nginx"
      "rules" = [
        {
          "host" = "pass.adyxax.org"
          "http" = {
            "paths" = [
              {
                "path"     = "/"
                "pathType" = "Prefix"
                "backend" = {
                  "service" = {
                    "name" = "pass"
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
          "secretName" = "wildcard-adyxax-org"
        },
      ]
    }
  }
}
```

### Certificate

For now I do not manage my certificates with terraform but manually. Once every two months I run :
```sh
acme.sh --config-home "$HOME/.acme.sh" --server letsencrypt --dns dns_cf --issue -d adyxax.org -d *.adyxax.org --force
kubectl -n pass create secret tls wildcard-adyxax-org --cert=$HOME/.acme.sh/adyxax.org/fullchain.cer \
  --key=$HOME/.acme.sh/adyxax.org/adyxax.org.key -o yaml --save-config --dry-run=client | kubectl apply -f -
```
