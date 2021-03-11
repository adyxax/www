---
title: "Ansible custom facts"
date: 2018-09-25
description: How to write custom facts with ansible
tags:
  - ansible
---

## Introduction

Custom facts are actually quite easy to implement despite the lack of documentation about it.

## How custom facts work

On any Ansible controlled host — that is, the remote machine that is being controlled and not the machine on which the playbook is run — you just need to create a directory at
`/etc/ansible/facts.d`. Inside this directory, you can place one or more `*.fact` files. These are files that must return JSON data, which will then be included in the raft of facts that
Ansible gathers.

The facts will be available to ansible at `hostvars.host.ansible_local.<fact_name>`.

## A simple example

Here is the simplest example of a fact, let's suppose we make it `/etc/ansible/facts.d/mysql.fact` :
{{< highlight sh >}}
#!/bin/sh
set -eu

echo '{"password": "xxxxxx"}'
{{< /highlight >}}

This will give you the fact `hostvars.host.ansible_local.mysql.password` for this machine.

## A more complex example

A more interesting example is something I use with small webapps. In the container that hosts the frontent I use a small ansible role to generate a mysql password on its first run, and
provision a database with a user that has access to it on a mysql server. This fact ensures that on subsequent runs we will stay idempotent.

First the fact from before, only slightly modified :
{{< highlight sh >}}
#!/bin/sh
set -eu

echo '{"password": "{{mysql_password}}"}'
{{< /highlight >}}

This fact is deployed with the following tasks :
{{< highlight yaml >}}
- name: Generate a password for mysql database connections if there is none
  set_fact: mysql_password="{{ lookup('password', '/dev/null length=15 chars=ascii_letters') }}"
  when: (ansible_local.mysql_client|default({})).password is undefined

- name: Deploy mysql client ansible fact to handle the password
  template:
    src: ../templates/mysql_client.fact
    dest: /etc/ansible/facts.d/
    owner: root
    mode: 0500
  when: (ansible_local.mysql_client|default({})).password is undefined

- name: reload ansible_local
  setup: filter=ansible_local
  when: (ansible_local.mysql_client|default({})).password is undefined

- name: Ensures mysql database exists
  mysql_db:
    name: '{{ansible_hostname}}'
    state: present
  delegate_to: "{{mysql_server}}"

- name: Ensures mysql user exists
  mysql_user:
    name: '{{ansible_hostname}}'
    host: '{{ansible_hostname}}'
    priv: '{{ansible_hostname}}.*:ALL'
    password: '{{ansible_local.mysql_client.password}}'
    state: present
  delegate_to: '{{mysql_server}}'
{{< /highlight >}}

## Caveat : a fact you deploy is not immediately available

Note that installing a fact does not make it exist before the next inventory run on the host. This can be problematic especially if you rely on facts caching to speed up ansible. Here
is how to make ansible reload facts using the setup tasks (If you paid attention you already saw me use it above).
{{< highlight yaml >}}
- name: reload ansible_local
  setup: filter=ansible_local
{{< /highlight >}}

## References

- https://medium.com/@jezhalford/ansible-custom-facts-1e1d1bf65db8
