---
title: "Updating dependencies"
date: 2026-02-04
description: "Shell scripting and a little know-how is all you need"
tags:
  - bash
---

## Introduction

I find most of the popular dependency update automation tools like Dependabot or
Renovate cumbersome to integrate, first and foremost because they cannot be run
locally easily. Secondly, they cover everything and the kitchen sink and you
cannot easily pick some languages or ecosystems to support. But if I could
somehow ignore that, sadly they are clunky even in a forge setting as soon as
you have to deal with private repositories and need to tightly manage access
control.

I understand how valuable these popular tools can be though, especially in
ecosystems that churn out new versions every other day. This makes these
dependency update automation tools a must have at work where you need to
reliably manage security updates across dozens of repositories I often do not
own.

Since I try to avoid dependencies as much as I can in my personal development
and infrastructure management, I believe I can get 90% of the value of these
tools for 10% of the complexity thanks to a few lighweight scripts.

## Updating dependencies

### Docker Hub

The Docker Hub offers the an API endpoint to check the latest tags on a specific
image. The trick is to write the right grep filter that will select only the
release tags you care about:

``` shell
local new_version
if ! new_version=$(curl -sSfL "https://hub.docker.com/v2/repositories/valkey/valkey/tags?page_size=100&ordering=last_updated" | \
    jq -r '.results|.[]|.name' | \
    grep -E '^[0-9](\.[0-9]){2}$'| \
    sort -V | \
    tail -n1); then
    echo "failed to get new version from docker hub tags" >&2; exit 1
fi
if [[ -z "$new_version" ]]; then
    echo "failed to get a non empty version from docker hub tags" >&2; exit 2
fi
if [[ "$new_version" != "$version" ]]; then
    echo "updating the repository to $project version $new_version"
    version="${version//./\\.}"
    sed -e "s!^version='$version'\$!version='$new_version'!" -i make.sh
fi
```

### Git tags

The Git CLI can be used quite efficiently to get the latest tags on a specific
repository. The trick is again to write the right filter the select only the
tags you care about:

``` shell
local new_seaweedfs_version
if ! new_seaweedfs_version=$(git ls-remote --tags --refs https://github.com/seaweedfs/seaweedfs | \
    perl -lane 'print $1 if /refs\/tags\/(\d.*)/'| \
    sort -V |
    tail -n1); then
    echo "failed to get new seaweedfs version from git RELEASE tags" >&2; exit 1
fi
if [[ -z "$new_seaweedfs_version" ]]; then
    echo "failed to get a non empty seaweedfs git RELEASE tag" >&2; exit 2
fi
if [[ "$new_seaweedfs_version" != "$seaweedfs_version" ]]; then
    echo "Updating the repository for $project version $new_seaweedfs_version"
    sed -e "s!^seaweedfs_version='$seaweedfs_version'\$!seaweedfs_version='$new_seaweedfs_version'!" -i make.sh
fi
```

### Go

The official Go website conveniently offers a simple API endpoint to check the
latest releases. I also update all module dependencies in this step for personal
convenience:

``` shell
local new_golang_version
if ! new_golang_version=$(curl -fsSL 'https://go.dev/dl/?mode=json' | \
                              jq -r '[.[] | select(.stable == true)][0].version' | \
                              sed -e 's/^go//'); then
    echo "failed to get new golang version from go.dev" >&2; exit 1
fi
if [[ -z "$new_golang_version" ]]; then
    echo "failed to get a non empty golang version number" >&2; exit 2
fi
sed -e "s/^go [0-9\\.]\+\$/go $new_golang_version/" -i go.mod
go get -t -u ./... && go mod tidy
```

### OpenTofu/Terraform

Fetching the latest versions of OpenTofu/Terraform providers is trickier
because proper parsing is needed to handle the files correctly.

I work around this by enforcing conventions. First I keep all provider
definitions and configurations separate in a `providers.tf` file. Then I keep
the `source =` and `version =` statements always sorted in that order (not a
problem for me because I sort everything alphabetically anywhere I can, but
critical for the script to work). I also do not use trailing comments for the
source and version statements.

Note that this will pick the latest versions of each provider, not necessarily
the latest compatible with your infrastructure code. One could update the script
to filter on the same major versions the code currently relies on, but I do not
bother in my personal circumstances and prefer to know and upgrade my code.

If I find any changes, I regenerate the Opentofu/Terraform lock file.

With this considered, I can forego proper parsing for the simpler:

``` shell
get_latest_version() {
    local source=$1 latest
    if ! latest=$(curl -fsSL "https://registry.terraform.io/v1/providers/${source}/versions" | \
                 jq -r '.versions[].version' | \
                 sort -V | tail -n1); then
        echo "failed to get $source tofu provider version from the registry" >&2; exit 1
    fi
    if [[ -z "$latest" ]]; then
        echo "failed to get a non empty $source tofu provider version number" >&2
        exit 2
    fi
    printf '%s' "$latest"
}

process_tf_file() {
    local line source
    while IFS= read -r line <&3; do
        if [[ "$line" =~ ^[[:space:]]+source[[:space:]]+=[[:space:]]\"([A-Za-z0-9/]+)\"$ ]]; then
            printf '%s\n' "$line" >&4
            source="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^([[:space:]]+version[[:space:]]+=[[:space:]])\"[0-9\.]+\"$ ]]; then
            printf '%s"%s"\n' "${BASH_REMATCH[1]}" "$(get_latest_version "$source")" >&4
        else
            printf '%s\n' "$line" >&4
        fi
    done
}
exec 3<providers.tf
exec 4>|providers_new.tf
process_tf_file
exec 3<&-
exec 4>&-
mv providers_new.tf providers.tf
if ! git diff --quiet providers.tf; then
    tofu providers lock -platform=linux_amd64
fi
```

## Conclusion

Dependency management and updates are tricky subjects, and I am a firm believer
that reducing the amount of dependencies is the best thing you can do in the
long term. Dependency management software is no exception in my view, as they
are another rather big dependency themselves.

Last but not least: this scripting approach makes me happy than I can discover
new updates and bump pinned versions with a few curl, jq commands and regexes
tailored to my stack.
