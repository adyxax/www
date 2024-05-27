---
title: CAA DNS records with OpenTofu
description: How I manage which acme CA can issue certificates for me
date: 2024-05-27
tags:
- opentofu
- terraform
---

# Introduction

Certification Authority Authorization (CAA) are a type of DNS records that allows the owner of a domain to restrict which Certificate Authority (CA) can emit a certificate for the domain. This is a protection mechanism that is easy to setup and that has absolutely no drawbacks.

One good reason to use CAA records in our modern world of servers running in the cloud is that when you decomission or change a server you very often lose access to its IP address and get a new one. If you mess up cleaning the old IP address from your DNS records and have no CAA records, someone who grabs it could then start issuing certificates for your domain.

# CAA records

## Basics

CAA record can be queried with your favorite DNS lookup utility (`dig`, `drill`, `nslookup`, etc). A basic example looks like this:
```
$ dig +short CAA adyxax.org
0 issue "letsencrypt.org"
0 issuewild "letsencrypt.org"
```

In this example, letsencrypt is authorized to issue both standard and wildcard certificates for the adyxax.org domain.

## Getting notified of wrongful attempts

There are severeal bits of syntax in the RFC that can be of interest, especially if you want to be notified when someone tries to issue a certificate from an unauthorized CA:

```
$ dig +short CAA adyxax.org
0 iodef "mailto:iodef+caa@adyxax.org"
0 issue "letsencrypt.org"
0 issuewild "letsencrypt.org"
```

## Securing a domain even further

There are other extensions that allow domain owners to restrict even more things like which certificate validation method can be used. Just keep in mind that these extensions will vary from CA to CA and you will need to read the documentation of your CA of choice. A letsencrypt locked down certificate issuance to a specific account ID with a specific validation method looks like this:

```
$ dig +short CAA adyxax.org
0 iodef "mailto:iodef+caa@adyxax.org"
0 issuewild "letsencrypt.org;validationmethods=dns-01;accounturi=https://acme-v02.api.letsencrypt.org/acme/acct/123456"
```

With this configuration, I can be pretty sure only I will be able to generate a (wildcard, other types are not authorized) certificate for my domain.

## Caveat

Note that some DNS providers that offer hosting services will sometimes provision invisible CAA records on your behalf and it might not be obvious this is happening. For example if your domain is hosted on cloudflare and you use their `pages` service, they will add CAA records to issue their certificates. You will be able to see these records using your lookup tool, but not if you look at your cloudflare dashboard.

# Opentofu code

The following code examples will first feature a standard version (suitable for AWS, GCP and other providers), and one for cloudflare. Cloudflare records are built different than other providers I know of because the Cloudflare terraform provider does some validation by itself while others simply rely on their APIs. Another important difference is that terraform resources use a list of records as input, while cloudflare forces you to create one resource per value you need for a record. Yes this will clutter your terraform states!

## Basic

Here is a simple definition for multiple zones managed the same way on AWS:
```hcl
locals {
  zones = toset([
    "adyxax.eu",
    "adyxax.org",
  ])
  cas = { for domain in local.zones :
    domain => ["letsencrypt.org", "example.com"]
  }
  caa_records = { for domain, records in local.caa_records :
    domain => flatten([for record in records :
      [for tag in ["issue", "issuewild"] : "0 ${tag} ${record}"]
    ])
  }
}

data "aws_route53_zone" "main" {
  for_each = local.zones

  name = each.key
}

resource "aws_route53_record" "caa" {
  for_each = local.caa_records

  name    = "@"
  records = each.value
  type    = "CAA"
  zone_id = data.cloudflare_zone.main[each.key].zone_id
}
```

The Cloudflare version is subtly different since we need records for each permutation of domain, CA domain and tag:
```hcl
locals {
  zones = toset([
    "adyxax.eu",
    "adyxax.org",
  ])
  cas = { for domain in local.zones :
    domain => ["letsencrypt.org", "example.com"]
  }
  caa_records = merge(flatten([for domain, records in local.cas :
    [for tag in ["issue", "issuewild"] :
      { for record in records : "${domain}_${tag}_${record}" => {
        domain = domain
        record = record
        tag    = tag
      } }
    ]
  ])...)
}

data "cloudflare_zone" "main" {
  for_each = local.zones

  name = each.key
}

resource "cloudflare_record" "caa" {
  for_each = local.caa_records

  data {
    flags = "0"
    tag   = each.value.tag
    value = each.value.record
  }
  name    = "@"
  type    = "CAA"
  zone_id = data.cloudflare_zone.main[each.value.domain].zone_id
}
```

## Advanced

Here is a more advanced definition that handles zones that have different needs than others, as well as CAs that have multiple signing domains like AWS does:
```hcl
locals {
  zones = {
    "adyxax.eu" = {
      caa = { "amazon" = ["issue"] }
    }
    "adyxax.org" = {
      caa = { "letsencrypt" = ["issue", "issuewild"] }
    }
    "anne-so-et-julien.fr" = {
      caa = {
        "amazon"      = ["issue"]
        "letsencrypt" = ["issuewild"]
      }
    }
  }
  cas = {
    amazon      = ["amazon.com", "amazontrust.com", "awstrust.com", "amazonaws.com"]
    letsencrypt = ["letsencrypt.org"]
  }
  caa_records = { for domain, data in local.zones :
    domain => flatten([for ca, tags in data.caa :
      [for record in local.cas[ca] :
        [for tag in tags : "0 ${tag} ${record}"]
      ]
    ])
  }

}

data "aws_route53_zone" "main" {
  for_each = local.zones

  name = each.key
}

resource "aws_route53_record" "caa" {
  for_each = local.caa_records

  name    = "@"
  records = each.value
  type    = "CAA"
  zone_id = data.cloudflare_zone.main[each.key].zone_id
}
```

The Cloudflare version is subtly different since we need records for each permutation of domain, CA domain and tag:
```hcl
locals {
  zones = {
    "adyxax.eu" = {
      caa = { "amazon" = ["issue"] }
    }
    "adyxax.org" = {
      caa = { "letsencrypt" = ["issue", "issuewild"] }
    }
    "anne-so-et-julien.fr" = {
      caa = {
        "amazon"      = ["issue"]
        "letsencrypt" = ["issuewild"]
      }
    }
  }
  cas = {
    amazon      = ["amazon.com", "amazontrust.com", "awstrust.com", "amazonaws.com"]
    letsencrypt = ["letsencrypt.org"]
  }
  caa_records = merge(flatten([for domain, data in local.zones :
    [for ca, tags in data.caa :
      [for record in local.cas[ca] :
        { for tag in tags : "${domain}_${tag}_${record}" => {
          domain = domain
          record = record
          tag    = tag
        } }
      ]
    ]
  ])...)
}

data "cloudflare_zone" "main" {
  for_each = local.zones

  name = each.key
}

resource "cloudflare_record" "caa" {
  for_each = local.caa_records

  data {
    flags = "0"
    tag   = each.value.tag
    value = each.value.record
  }
  name    = "@"
  type    = "CAA"
  zone_id = data.cloudflare_zone.main[each.value.domain].zone_id
}
```

# Conclusion

I hope I showed you that CAA records are both useful and accessible. Please start propecting your domains with CAA records now!
