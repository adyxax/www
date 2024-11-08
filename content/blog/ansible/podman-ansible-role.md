---
title: 'Podman ansible role'
description: 'The ansible role I use to manage my podman containers'
date: '2024-11-08'
tags:
- ansible
- podman
---

## Introduction

Before succumbing to nixos, I had was running all my containers on k3s. This time I am migrating things to podman and trying to achieve a lighter setup. This article presents the ansible role I wrote to manage podman containers.

## The role

### Tasks

The main tasks file setups podman and the required network configurations with:

``` yaml
---
- name: 'Run OS specific tasks for the podman role'
  include_tasks: '{{ ansible_distribution }}.yaml'

- name: 'Make podman scripts directory'
  file:
    path: '/etc/podman'
    mode: '0700'
    owner: 'root'
    state: 'directory'

- name: 'Deploy podman configuration files'
  copy:
    src: 'cni-podman0'
    dest: '/etc/network/interfaces.d/'
    owner: 'root'
    mode: '444'
```

My OS specific task file `Debian.yaml` looks like this:

``` yaml
---
- name: 'Install podman dependencies'
  ansible.builtin.apt:
    name:
      - 'buildah'
      - 'podman'
      - 'rootlesskit'
      - 'slirp4netns'

- name: 'Deploy podman configuration files'
  copy:
    src: 'podman-bridge.json'
    dest: '/etc/cni/net.d/87-podman-bridge.conflist'
    owner: 'root'
    mode: '444'
```

The entrypoint tasks for this role is the `container.yaml` task file:

``` yaml
---
# Inputs:
#   container:
#     cmd: optional(list(string))
#     env_vars: list(env_var)
#     image: string
#     name: string
#     publishs: list(publish)
#     volumes: list(volume)
# With:
#   env_var:
#     name: string
#     value: string
#   publish:
#     container_port: string
#     host_port: string
#     ip: string
#   volume:
#     dest: string
#     src: string

- name: 'Deploy podman systemd service for {{ container.name }}'
  template:
    src: 'container.service'
    dest: '/etc/systemd/system/podman-{{ container.name }}.service'
    owner: 'root'
    mode: '0444'
  notify: 'systemctl daemon-reload'

- name: 'Deploy podman scripts for {{ container.name }}'
  template:
    src: 'container-{{ item }}.sh'
    dest: '/etc/podman/{{ container.name }}-{{ item }}.sh'
    owner: 'root'
    mode: '0500'
  register: 'deploy_podman_scripts'
  loop:
    - 'start'
    - 'stop'

- name: 'Restart podman container {{ container.name }}'
  shell:
    cmd: "systemctl restart podman-{{ container.name }}"
  when: 'deploy_podman_scripts.changed'

- name: 'Start podman container {{ container.name }} and activate it on boot'
  service:
    name: 'podman-{{ container.name }}'
    enabled: true
    state: 'started'
```

### Handlers

There is a single `main.yaml` handler:

``` yaml
---
- name: 'systemctl daemon-reload'
  shell:
    cmd: 'systemctl daemon-reload'
```

### Files

Here is the `cni-podman0` I deploy on Debian hosts. It is required for the bridge to be up on boot so that other services can bind ports on it. Without this, the bridge would only come up when the first container starts which is too late in the boot process.

``` text
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

auto cni-podman0
iface cni-podman0 inet static
address 10.88.0.1/16
pre-up brctl addbr cni-podman0
post-down brctl delbr cni-podman0
```

Here is the JSON cni bridge configuration file I use, customized to add IPv6 support:

``` json
{
  "cniVersion": "0.4.0",
  "name": "podman",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni-podman0",
      "isGateway": true,
      "ipMasq": true,
      "hairpinMode": true,
      "ipam": {
        "type": "host-local",
        "routes": [
          {
            "dst": "0.0.0.0/0"
          }, {
            "dst": "::/0"
          }
        ],
        "ranges": [
          [{
            "subnet": "10.88.0.0/16",
            "gateway": "10.88.0.1"
          }], [{
            "subnet": "fd42::/48",
            "gateway": "fd42::1"
          }]
        ]
      }
    }, {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }, {
      "type": "firewall"
    }, {
      "type": "tuning"
    }
  ]
}
```

### Templates

Here is the jinja templated start bash script:

``` shell
#!/usr/bin/env bash
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################
set -euo pipefail

podman rm -f {{ container.name }} || true
rm -f /run/podman-{{ container.name }}.ctr-id

exec podman run \
  --rm \
  --name={{ container.name }} \
  --log-driver=journald \
  --cidfile=/run/podman-{{ container.name }}.ctr-id \
  --cgroups=no-conmon \
  --sdnotify=conmon \
  -d \
{% for env_var in container.env_vars | default([]) %}
  -e {{ env_var.name }}={{ env_var.value }} \
{% endfor %}
{% for publish in container.publishs | default([]) %}
  -p {{ publish.ip }}:{{ publish.host_port }}:{{ publish.container_port }} \
{% endfor %}
{% for volume in container.volumes | default([]) %}
  -v {{ volume.src }}:{{ volume.dest }} \
{% endfor %}
  {{ container.image }} {% for cmd in container.cmd | default([]) %}{{ cmd }} {% endfor %}
```

Here is the jinja templated stop bash script:

``` shell
#!/usr/bin/env bash
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################
set -euo pipefail

if [[ ! "$SERVICE_RESULT" = success ]]; then
    podman stop --ignore --cidfile=/run/podman-{{ container.name }}.ctr-id
fi

podman rm -f --ignore --cidfile=/run/podman-{{ container.name }}.ctr-id
```

Here is the jinja templated systemd unit service:

``` shell
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

[Unit]
After=network-online.target
Description=Podman container {{ container.name }}

[Service]
ExecStart=/etc/podman/{{ container.name }}-start.sh
ExecStop=/etc/podman/{{ container.name }}-stop.sh
NotifyAccess=all
Restart=always
TimeoutStartSec=0
TimeoutStopSec=120
Type=notify

[Install]
WantedBy=multi-user.target
```

## Usage example

I do not call the role from a playbook, I prefer running the setup from an application’s role that relies on podman using a meta/main.yaml containing something like:

``` yaml
---
dependencies:
  - role: 'borg'
  - role: 'nginx'
  - role: 'podman'
```

Then from a tasks file:

``` yaml
- include_role:
    name: 'podman'
    tasks_from: 'container'
  vars:
    container:
      cmd: ['--config-path', '/srv/cfg/conf.php']
      name: 'privatebin'
      env_vars:
        - name: 'PHP_TZ'
          value: 'Europe/Paris'
        - name: 'TZ'
          value: 'Europe/Paris'
      image: 'docker.io/privatebin/nginx-fpm-alpine:1.7.4'
      publishs:
        - container_port: '8080'
          host_port: '8082'
          ip: '127.0.0.1'
      volumes:
        - dest: '/srv/cfg/conf.php:ro'
          src: '/etc/privatebin.conf.php'
        - dest: '/srv/data'
          src: '/srv/privatebin'
```

## Conclusion

I enjoy this design, it works really well. I am missing a task for deprovisioning a container but I have not needed it yet.
