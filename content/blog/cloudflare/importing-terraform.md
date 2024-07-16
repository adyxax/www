---
title: Importing cloudflare DNS records in terraform/opentofu
description: a way to get the records IDs
date: 2024-07-16
tags:
- cloudflare
- opentofu
- terraform
---

## Introduction

Managing cloudflare DNS records using terraform/opentofu is easy enough, but importing existing records into your automation is not straightforward.

## The problem

Contrary to AWS, GCP and (I think) all other providers, a `cloudflare_record` terraform resource only specifies one potential value of the DNS record. Because of that, you cannot import the resource using a record's name since it can have multiple record values: you need a cloudflare record ID for that.

Sadly these IDs are elusive and I did not find a way to get those from the webui dashboard. As best as I can tell, you have to query cloudflare's API to get this information.

## Querying the API

Most examples around the Internet make use of the old way of authenting with an email and an API key. The modern way is with an API token! An interesting fact is that while not straightforwardly specified, you can use it as a Bearer token. Here is the little script I wrote for this purpose:

``` shell
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "usage: $(basename $0) <zone-name> <record-type> <record-name>"
    exit 1
else
    ZONE_NAME="$1"
    RECORD_TYPE="$2"
    RECORD_NAME="$3"
fi

if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
    echo "Please export a CLOUDFLARE_API_TOKEN environment variable prior to running this script" >&2
    exit 1
fi

BASE_URL="https://api.cloudflare.com"

get () {
    REQUEST="$1"
    curl -s -X GET "${BASE_URL}${REQUEST}" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
         -H "Content-Type: application/json" | jq -r '.result[] | .id'
}

ZONE_ID=$(get "/client/v4/zones?name=${ZONE_NAME}")

get "/client/v4/zones/${ZONE_ID}/dns_records?name=${RECORD_NAME}&type=${RECORD_TYPE}"
```

## Conclusion

It works perfectly: with this script I managed to run my `tofu import cloudflare_record.factorio XXXX/YYYY` command and get on with my work.
