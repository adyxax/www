---
title: Syncthing ansible role
date: 2023-01-21
description: The ansible role I wrote to manage my syncthing configurations
tags:
- ansible
- syncthing
---

## Introduction

I have been using [syncthing](https://syncthing.net/) for some time now. It is a tool to handle bidirectional synchronization of data. For example I use it on my personal infrastructure to synchronize:
- org-mode files between my workstation, laptop, a server and my phone (I need those everywhere!)
- pictures from my phone and my nas
- my music collection between my phone and my nas

It is very useful, but by default the configuration leave a few things to be desired like telemetry or information leaks. If you want maximum privacy you need to disable the auto discovery and the default nat traversal features.

Also provisioning is easy, but deleting or unsharing stuff would require to remember what is shared where and go manage each device individually from syncthing's web interface. I automated all that with ansible (well except for my phone which I cannot manage with ansible, its syncthing configuration will remain manual... for now).

## Why another ansible role

I wanted a role to install and configure syncthing for me and did not find an existing one that satisfied me. I had a few mandatory features in mind:
- the ability to configure a servers parameters in only one place to avoid repetition
- having a fact that retrieves the ID of a device
- the validation of host_vars which virtually no role in the wild ever does
- the ability to manage an additional inventory file for devices which ansible cannot manage (like my phone)

## Role variables

There is a single variable to specify in the `host_vars` of your hosts: `syncthing`. This is a dict that can contain the following keys:
- address: optional string to specify how to connect to the server, must match the format `tcp://<hostname>` or `tcp://<ip>`. Default value is *dynamic* which means a passive host.
- shared: a mandatory dict describing the directories this host shares, which can contain the following keys:
  - name: a mandatory string to name the share in the configuration. It must match on all devices that share this folder.
  - path: the path of the folder on the device. This can differ on each device sharing this data.
  - peers: a list a strings. Each item should be either the `ansible_hostname` of another device, or a hostname from the `syncthing_data.yaml` file

Configuring a host through its `host_vars` looks like this:
```yaml
syncthing:
  address: tcp://lore.adyxax.org
  shared:
    - name: org-mode
      path: /var/syncthing/org-mode
      peers:
        - hero
        - light
        - lumapps
        - Pixel 3a
```

## The optional syncthing_data.yaml file

To be found by the `action_plugins`, this file should be in the same folder as your playbook. It shares the same format as the `host_vars` but with additional keys for the hostname and its ID.

The data file for non ansible devices looks like this:
```yaml
- name: Pixel 3a
  id: ABCDEFG-HIJKLMN-OPQRSTU-VWXYZ01-2345678-90ABCDE-FGHIJKL-MNOPQRS
  shared:
    - name: Music
      path: /storage/emulated/0/Music
      peers:
        - phoenix
    - name: Photos
      path: /storage/emulated/0/DCIM/Camera
      peers:
        - phoenix
    - name: org-mode
      path: /storage/emulated/0/Org
      peers:
        - lore.adyxax.org
```

## Example playbook

```yaml
- hosts: all
  roles:
    -  {  role:  syncthing, tags: [ 'syncthing' ], when: "syncthing is defined" }
```

## Conclusion

You can find the role [here](https://git.adyxax.org/adyxax/syncthing-ansible-role/about/). If I left something unclear or some piece seems to be missing, do not hesitate to [contact me]({{< ref "about-me.md" >}}).
