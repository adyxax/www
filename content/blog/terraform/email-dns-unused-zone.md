---
title: Email DNS records for zones that do not send emails
description: Automated with terraform/OpenTofu
date: 2024-09-03
tags:
- cloudflare
- DNS
- OpenTofu
- terraform
---

## Introduction

There are multiple DNS records one needs to configure in order to setup and securely use a domain to send or receive emails: MX, DKIM, DMARC and SPF.

An often overlooked fact is that you also need to configure some of these records even if you do not intend to use a domain to send emails. If you do not, scammers will spoof your domain to send fraudulent emails and your domain's reputation will suffer.

## DNS email records you need

### SPF

The most important and only required record you need is a TXT record on the apex of your domain that advertises the fact that no server can send emails from your domain:
```
"v=spf1 -all"
```

### MX

If you do not intend to ever send emails, you certainly do not intend to receive emails either. Therefore you should consider removing all MX records on your zone. Oftentimes your registrar will provision some pointing to a free email infrastructure that they provide along with your domain.

### DKIM

You do not need DKIM records if you are not sending emails.

### DMARC

While not strictly necessary, I strongly recommend to set a DMARC record that instructs the world to explicitly reject all emails not matching the SPF policy:

```
"v=DMARC1;p=reject;sp=reject;pct=100"
```

## Terraform / OpenTofu code

### Zones

I use a map of simple objects to specify email profiles for my DNS zones:
``` hcl
locals {
  zones = {
    "adyxax.eu"            = { emails = "adyxax" }
    "adyxax.org"           = { emails = "adyxax" }
    "anne-so-et-julien.fr" = { emails = "no" }
  }
}

data "cloudflare_zone" "main" {
  for_each = local.zones

  name = each.key
}
```

### SPF

Then I map each profile to spf records:
``` hcl
locals {
  spf = {
    "adyxax" = "v=spf1 mx -all"
    "no"     = "v=spf1 -all"
  }
}

resource "cloudflare_record" "spf" {
  for_each = local.zones

  name    = "@"
  type    = "TXT"
  value   = local.spf[each.value.emails]
  zone_id = data.cloudflare_zone.main[each.key].id
}
```

### DMARC

The same mapping system we had for spf can be used here too, but I choose to keep things simple and in the scope of this article. My real setup has some clever tricks to make dmarc notifications work centralized to a single domain that will be the subject another post:

``` hcl
resource "cloudflare_record" "dmarc" {
  for_each = { for name, info in local.zones :
    name => info if info.emails == "no"
  }

  name    = "@"
  type    = "TXT"
  value   = "v=DMARC1;p=reject;sp=reject;pct=100"
  zone_id = data.cloudflare_zone.main[each.key].id
}
```

## Conclusion

Please keep your email DNS records tight and secure!
