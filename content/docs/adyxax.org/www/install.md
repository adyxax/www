---
title: "Installation"
description: Installation notes of www on k3s
---

## Introduction

This is a static website built using hugo.

## Kubernetes manifest

[The whole manifest is here](https://git.adyxax.org/adyxax/www/tree/deploy/www.yaml).

## DNS CNAME

Terraform is only used for the dns record on this app for legacy reasons

```hcl
resource "cloudflare_record" "pass-cname" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "www"
  value   = "myth.adyxax.org"
  type    = "CNAME"
  proxied = false
}
```

## Certificate

For now I do not manage my certificates with terraform but manually. Once every two months I run :
```sh
acme.sh --config-home "$HOME/.acme.sh" --server letsencrypt --dns dns_cf --issue -d adyxax.org -d *.adyxax.org --force
kubectl -n www create secret tls wildcard-adyxax-org --cert=$HOME/.acme.sh/adyxax.org/fullchain.cer \
  --key=$HOME/.acme.sh/adyxax.org/adyxax.org.key -o yaml --save-config --dry-run=client | kubectl apply -f -
```
