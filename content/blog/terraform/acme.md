---
title: Certificate management with OpenTofu and eventline
description: How I manage for my personal infrastructure
date: 2024-03-06
tags:
- Eventline
- OpenTofu
- terraform
---

## Introduction

In this article, I will explain how I handle the management and automatic renewal of SSL certificates on my personal infrastructure using OpenTofu (the fork of terraform) and [eventline](https://www.exograd.com/products/eventline/). I chose to centralise the renewal on my single host running eventline and to generate a single wildcard certificate for each domain I manage.

## Wildcard certificates

Many guides all over the internet advocate for one certificate per domain, and even more guides advocate for handling certificates with certbot or an acme aware server like caddy. That's is fine for some usage but I favor generating a single wildcard certificate and deploying it where needed.

My main reason is that I have a lot of sub-domains for various applications and services (about 45) which would really be flirting with the various limits in place for lets-encrypt if I used a different certificate for each one. This would be bad in case of migrations (or a disaster recovery) that would renew many certificates all at the same time: I could hit a daily quota and be stuck with a downtime.

The main consequence of this choice is that since it is a wildcard certificate, I have to answer a DNS challenge when generating the certificate. I answer this DNS challenge thanks to the cloudflare integration of the provider.

## Terraform code

### Providers

Here is the configuration for the providers. There is one provider for acme negotiations, one to generate rsa keys and of course eventline.
```hcl
terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
    eventline = {
      source = "adyxax/eventline"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
```

Since I am using lets-encrypt, I configure the acme provider this way:
```hcl
provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
```

Eventline requires the following too:
```hcl
variable "eventline_api_key" {}
provider "eventline" {
  api_key  = var.eventline_api_key
  endpoint = "https://eventline-api.adyxax.org/"
}
```

The tls provider does not require any configuration.

### Getting the certificates

First we need to register with the acme certification authority:
```hcl
resource "tls_private_key" "acme-registration-adyxax-org" {
  algorithm = "RSA"
}

resource "acme_registration" "adyxax-org" {
  account_key_pem = tls_private_key.acme-registration-adyxax-org.private_key_pem
  email_address   = "root+letsencrypt@adyxax.org"
}
```

The certificate is requested with:
```hcl
resource "acme_certificate" "adyxax-org" {
  account_key_pem           = acme_registration.adyxax-org.account_key_pem
  common_name               = "adyxax.org"
  subject_alternative_names = ["adyxax.org", "*.adyxax.org"]

  dns_challenge {
    provider = "cloudflare"
    config = {
      CF_API_EMAIL = var.cloudflare_adyxax_login
      CF_API_KEY   = var.cloudflare_adyxax_api_key
    }
  }
}
```

### Deploying the certificate

I am using two eventline generic identities to pass along the certificate and its private key:
```hcl
data "eventline_project" "main" {
  name = "main"
}
resource "eventline_identity" "adyxax-org-cert" {
  project_id = data.eventline_project.main.id
  name       = "adyxax-org-fullchain"
  type       = "password"
  connector  = "generic"
  data = jsonencode({ "password" = format("%s%s",
    acme_certificate.adyxax-org.certificate_pem,
    acme_certificate.adyxax-org.issuer_pem,
  ) })
  provisioner "local-exec" {
    command = "evcli execute-job --wait --fail certificates-deploy"
  }
}
resource "eventline_identity" "adyxax-org-key" {
  project_id = data.eventline_project.main.id
  name       = "adyxax-org-key"
  type       = "password"
  connector  = "generic"
  data       = jsonencode({ "password" = acme_certificate.adyxax-org.private_key_pem })
}
```

The `format` function in the certificate file contents is here to concatenate the certificate with the issuer information in order to generate a fullchain.

The `local-exec` terraform provisioner is a way to trigger the eventline job that deploys the certificate everywhere it is used. Depending on the hosts, this is performed via `scp` the certificates then `ssh` to reload or restart daemons, via `nixos-rebuild` or via `kubectl apply`.

If you are not using eventline, you can get your key and certificate out of the terraform state using something like:
```hcl
resource "local_file" "wildcard_adyxax-org_crt" {
  filename        = "adyxax.org.crt"
  file_permission = "0600"
  content = format("%s%s",
    acme_certificate.adyxax-org.certificate_pem,
    acme_certificate.adyxax-org.issuer_pem,
  )
}

resource "local_file" "wildcard_adyxax-org_key" {
  filename        = "adyxax.org.key"
  file_permission = "0600"
  content         = acme_certificate.adyxax-org.private_key_pem
}
```

## Eventline

I talked about eventline in previous blog articles:
- [Testing eventline]({{< ref "blog/miscellaneous/eventline.md" >}})
- [Installation notes of eventline on FreeBSD]({{< ref "eventline-2.md" >}})

I am still a very happy eventline user, it is a reliable piece of software that manages my scripts and scheduled jobs really well. It does it so well that I am entrusting my certificates management to eventline.

The job that deploys the certificate over ssh looks like the following:
```yaml
name: "certificates-deploy"
steps:
  - label: make deploy
    script:
      path: "./certificates-deploy.sh"
identities:
  - adyxax-org-fullchain
  - adyxax-org-key
  - ssh
```

The script looks like:
```sh
#!/usr/bin/env bash
set -euo pipefail

CRT="${EVENTLINE_DIR}/identities/adyxax-org-fullchain/password"
KEY="${EVENTLINE_DIR}/identities/adyxax-org-key/password"
SSHKEY="${EVENTLINE_DIR}/identities/ssh/private_key"

SSHOPTS="-i ${SSHKEY} -o StrictHostKeyChecking=accept-new"

scp ${SSHOPTS} "${KEY}" root@yen.adyxax.org:/etc/nginx/adyxax.org.key
scp ${SSHOPTS} "${CRT}" root@yen.adyxax.org:/etc/nginx/adyxax.org-fullchain.cer
ssh ${SSHOPTS} root@yen.adyxax.org rcctl restart nginx
```

For updating the certificate used by some Kubernetes ingress, I pass an identity with a kubecontext and access it in a similar way. For nixos hosts, the job is a bit more complex since I first need to clone the repository with my nixos configurations before updating the certificate and rebuilding.

I have another eventline job which gets triggered once every 10 weeks (so a little bellow the three months valid duration of letsencrypt's certificates) that runs a targeted tofu apply for me.

## Conclusion

As usual if you need more information to implement this kind of renewal process you can [reach me by email or on mastodon]({{< ref "about-me.md" >}}#how-to-get-in-touch). If you have not yet tested eventline to manage your scripts I highly recommend you do so!
