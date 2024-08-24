---
title: Generating a github access token for a github app in bash
description: A useful script
date: 2024-08-24
tags:
- bash
- github
---

## Introduction

Last week I had to find a way to generate a github access token for a github app.

## The problem

Github apps are the newest and recommended way to provide programmatic access to things that need to interact with github. You get some credentials that allow you to authenticate then generate some JWT which you can use to generate an access key... Lovely!

When developping an "app", all this complexity mostly makes sense, but when all you want is to run some script it really gets in the way. From my research most people in this situation give up on github apps and either create a robot account, or bite the bullet and create personnal access tokens. The people who resist and try to do the right thing mostly end up with some nodejs and quite a few dependencies.

I needed something simpler.

## The script

I took a lot of inspiration from [this script](https://github.com/Nastaliss/get-github-app-pat/blob/main/generate_github_access_token.sh), cleaned it up and ended up with:

``` shell
#!/usr/bin/env bash
# This script generates a github access token. It Requires the following
# environment variables:
# - GITHUB_APP_ID
# - GITHUB_APP_INSTALLATION_ID
# - GITHUB_APP_PRIVATE_KEY
set -euo pipefail

b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
NOW=$(date +%s)

HEADER=$(printf '{
    "alg": "RS256",
    "exp": %d,
    "iat": %d,
    "iss": "adyxax",
    "kid": "0001",
    "typ": "JWT"
}' "$((NOW+10))" "${NOW}" | jq -r -c .)

PAYLOAD=$(printf '{
    "exp": %s,
    "iat": %s,
    "iss": %s
}' "$((NOW + 10 * 59))" "$((NOW - 10))" "${GITHUB_APP_ID}" | jq -r -c .)

SIGNED_CONTENT=$(printf '%s' "${HEADER}" | b64enc).$(printf '%s' "${PAYLOAD}" | b64enc)
SIG=$(printf '%s' "${SIGNED_CONTENT}" | \
    openssl dgst -binary -sha256 -sign <(printf "%s" "${GITHUB_APP_PRIVATE_KEY}") | b64enc)
JWT=$(printf '%s.%s' "${SIGNED_CONTENT}" "${SIG}")

curl -s --location --request POST \
     "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens" \
     --header "Authorization: Bearer $JWT" \
     --header 'Accept: application/vnd.github+json' \
     --header 'X-GitHub-Api-Version: 2022-11-28' | jq -r '.token'
```

## Conclusion

It works, is simple and only requires bash, jq and openssl.
