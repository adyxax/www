---
title: "Dump all ansible variables"
linkTitle: "Dump all ansible variables"
date: 2019-10-15
description: >
  How to dump all variables used by ansible
---

Here is the task to use in order to achieve that :

{{< highlight yaml >}}
- name: Dump all vars
  action: template src=dumpall.j2 dest=ansible.all
{{< /highlight >}}

And here is the template to use with it :

{{< highlight jinja >}}
Module Variables ("vars"):
--------------------------------
{{ vars | to_nice_json }}

Environment Variables ("environment"):
--------------------------------
{{ environment | to_nice_json }}

GROUP NAMES Variables ("group_names"):
--------------------------------
{{ group_names | to_nice_json }}

GROUPS Variables ("groups"):
--------------------------------
{{ groups | to_nice_json }}

HOST Variables ("hostvars"):
--------------------------------
{{ hostvars | to_nice_json }}
{{< /highlight >}}
