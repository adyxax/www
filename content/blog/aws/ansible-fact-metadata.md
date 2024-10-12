---
title: 'Shell script for gathering imdsv2 instance metadata on AWS ec2'
description: 'An ansible fact I wrote'
date: '2024-10-12'
tags:
- ansible
- aws
---

## Introduction

I wrote a shell script to gather ec2 instance metadata with an ansible fact.

## The script

I am using POSIX `/bin/sh` because I wanted to support a variety of operating systems. Besides that, the only dependency is `curl`:

``` shell
#!/bin/sh
set -eu

metadata() {
    local METHOD=$1
    local URI_PATH=$2
    local TOKEN="${3:-}"
    local HEADER
    if [ -z "${TOKEN}" ]; then
        HEADER='X-aws-ec2-metadata-token-ttl-seconds: 21600' # request a 6 hours token
    else
        HEADER="X-aws-ec2-metadata-token: ${METADATA_TOKEN}"
    fi
    curl -sSfL --request "${METHOD}" \
         "http://169.254.169.254/latest${URI_PATH}" \
         --header "${HEADER}"
}

METADATA_TOKEN=$(metadata PUT /api/token)
KEYS=$(metadata GET /meta-data/tags/instance "${METADATA_TOKEN}")
PREFIX='{'
for KEY in $KEYS; do
    VALUE=$(metadata GET "/meta-data/tags/instance/${KEY}" "${METADATA_TOKEN}")
    printf '%s"%s":"%s"' "${PREFIX}" "${KEY}" "${VALUE}"
    PREFIX=','
done
printf '}'
```

## Bonus version without depending on curl

Depending on curl can be avoided. If you are willing to use netcat instead and be declared a madman by your colleagues, you can rewrite the function with:

``` shell
metadata() {
    local METHOD=$1
    local URI_PATH=$2
    local TOKEN="${3:-}"
    local HEADER
    if [ -z "${TOKEN}" ]; then
        HEADER='X-aws-ec2-metadata-token-ttl-seconds: 21600' # request a 6 hours token
    else
        HEADER="X-aws-ec2-metadata-token: ${METADATA_TOKEN}"
    fi
    printf "${METHOD} /latest${URI_PATH} HTTP/1.0\r\n%s\r\n\r\n" \
           "${HEADER}" \
           | nc -w 5 169.254.169.254 80 | tail -n 1
}
```

## Deploying an ansible fact

I deploy the script this way:
``` yaml
- name: 'Deploy ec2 metadata fact gathering script'
  copy:
    src: 'ec2_metadata.sh'
    dest: '/etc/ansible/facts.d/ec2_metadata.fact'
    owner: 'root'
    mode: '0500'
  register: 'ec2_metadata_fact'

- name: 'reload facts'
  setup: 'filter=ansible_local'
  when: 'ec2_metadata_fact.changed'
```

## Conclusion

It works, is simple and I like it. I am happy!
