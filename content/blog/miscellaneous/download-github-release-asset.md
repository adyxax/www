---
title: Scripting the download of a private repository's GitHub release asset
date: 2025-11-13
description: bash, curl and jq
tags:
  - GitHub
---

## Introduction

Last week I needed to script the download of a specific asset from a release of
a private GitHub repository. It turns out that there is no direct way to do this
as you first need to resolve the asset name into an ID. Here is a little script
that does just that without any big dependency like the `gh` CLI.

## The script

```sh
#!/usr/bin/env bash
set -euCo pipefail

github_pat="XXXXXX"
owner="adyxax"
repository="private-repository"
regex=".*-linux-x86_64.tar.gz"
tag="v2025.11.06.0402"

if ! releases=$(curl -fsSL \
        "https://api.github.com/repos/$owner/$repository/releases/tags/$tag" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: token $github_pat" \
        -H "X-GitHub-Api-Version: 2022-11-28"); then
    echo "failed to get latest release assets from GitHub" >&2; exit 1
fi

value=$(printf '%s' "$releases" \
      | jq -r --arg regex "$regex" \
           'first(.assets
                 |to_entries[]
                 |select(.value.name
                     |test($regex))
                 |.value)')

id=$(printf '%s' "$value" | jq -r '.id')
filename=$(printf '%s' "$value" | jq -r '.name')

if ! curl -fsSL "https://api.github.com/repos/$owner/$repository/releases/assets/$id" \
        -H "Accept: application/octet-stream" \
        -H "Authorization: token $github_pat" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -o "$filename"; then
    echo "failed to download asset from GitHub" >&2; exit 2
fi
```

## Conclusion

This is simple and works well. Scripting is fun!
