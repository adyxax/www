---
title: "Ansible vault example"
date: 2018-02-21
description: Getting started with ansible vault
tags:
  - ansible
---

## Editing a protected file

Here is how to edit a vault protected file :
{{< highlight sh >}}
ansible-vault edit hostvars/blah.yml
{{< / highlight >}}

## Using a vault entry in a task or a jinja template

It is as simple as using any variable :
{{< highlight yaml >}}
- copy:
    path: /etc/ssl/private.key
    mode: 0400
    content: '{{ ssl_key }}'
{{< / highlight >}}

## How to specify multiple lines entries

This is actually a yaml question, not a vault one but since I ask myself this frequently in this context here is how to put a multiple lines entry like a private key in vault (for a simple value, just don't use a `|`):

{{< highlight yaml >}}
ssl_key : |
  ----- BEGIN PRIVATE KEY -----
  blahblahblah
  blahblahblah
  ----- END PRIVATE KEY -----
{{< /highlight >}}

## How to run playbooks when vault values are needed

To run a playbook, you will need to pass the `--ask-vault` argument or to export a `ANSIBLE_VAULT_PASSWORD_FILE=/home/julien/.vault_pass.txt` variable (the file needs to contain a single line with your vault password here).

## Ressources

  * how to break long lines in ansible : https://watson-wilson.ca/blog/2018/07/11/ansible-tips/
