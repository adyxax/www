---
title: "Ansible vault example"
linkTitle: "Ansible vault example"
date: 2018-02-21
description: >
  Ansible vault example
---

Here is how to edit a vault protected file :
{{< highlight sh >}}
ansible-vault edit hostvars/blah.yml
{{< / highlight >}}

Here is how to put a multiline entry like a private key in vault (for a simple value, just don't use a `|`):

{{< highlight yaml >}}
ssl_key : |
  ----- BEGIN PRIVATE KEY -----
  blahblahblah
  blahblahblah
  ----- END PRIVATE KEY -----
{{< /highlight >}}

And here is how to use it in a task :
{{< highlight yaml >}}
- copy:
    path: /etc/ssl/private.key
    mode: 0400
    content: '{{ ssl_key }}'
{{< / highlight >}}

To run a playbook, you will need to pass the `--ask-vault` argument or to export a `ANSIBLE_VAULT_PASSWORD_FILE=/home/julien/.vault_pass.txt` variable (the file needs to contain a single line with your vault password here).

## Ressources

  * how to break long lines in ansible : https://watson-wilson.ca/blog/2018/07/11/ansible-tips/
