---
title: "Start OpenSSH from the FreeBSD installer"
description: "It takes more than one command"
date: "2026-11-02"
tags:
- FreeBSD
---

## Introduction

This article explains how to start an OpenSSH server from the FreeBSD installer.
It is usually quite easy to do on Linux, but on FreeBSD it requires a few
commands that I want to document here. My use case is a web KVM or virtual
machine VNC or SPICE interface that restrict copy/paste operations during rescue
or install operations.

## Procedure

First, boot the installation media normally then select "Shell" on the first
menu screen. Then set up the network however is appropriate in your situation,
for example:

``` shell
dhclient vtnet0
```

Set up OpenSSH:

``` shell
mkdir -p /tmp/sshd/etc/ssh
ssh-keygen -A -f /tmp/sshd
fetch -o /tmp/sshd/authorized_keys https://git.adyxax.org/adyxax.keys
cat > /tmp/sshd/sshd_config <<'EOF'
Port 22
HostKey /tmp/sshd/etc/ssh/ssh_host_ed25519_key
HostKey /tmp/sshd/etc/ssh/ssh_host_rsa_key
PermitRootLogin without-password
PasswordAuthentication no
AuthorizedKeysFile /tmp/sshd/authorized_keys
PidFile /tmp/sshd/sshd.pid
StrictModes no
EOF
/usr/sbin/sshd -f /tmp/sshd/sshd_config
```

Then SSH in with (updating the port and hostname to your circumstances):

``` shell
ssh -o UserKnownHostsFile=/dev/null -p10022 root@localhost
```

I like to ignore these one time use host keys in rescue/install situations.

## How it works

The main thing we need to work around is that the installation media is mounted
read-only, and is missing a working minimal configuration. When using a Linux
installation media, you can usually just start sshd and it works with a default
environment and default SSH host keys, but not on FreeBSD.

The snippet above creates a temporary environment for OpenSSH under /tmp by
creating SSH host keys, fetching my SSH public key from my Forgejo instance (you
could do the same from GitHub), then writing a minimal configuration.

In this configuration, one surprising thing might be the `StrictModes no`
option: it is necessary because we are under `/tmp` which is world writable.
`PermitRootLogin` is necessary because `root` is the only account, and we cannot
set a password on a read-only `/`. Also a `PidFile` is needed because the
default `/var/run` is read-only too.

Finally, `sshd` refuses to start without specifying its full path.

## Optional: how to paste such a snippet efficiently

As mentioned in the introduction, my use case is a web KVM or virtual machine
VNC or SPICE interface that restrict copy/paste operations during rescue or
install operations. This makes typing that many lines of commands and
configuration quite inconvenient!

My usual solution to this is `xdotool`, but it can be unreliable when paired
with a web KVM. These usually eat newline characters and you need to throttle
the input a bit for it to work properly. I use the following `xdotype` wrapper
script:

``` shell
#!/bin/sh
# usage: xdotype FILE (or: cmd | xdotype -)
# You have 2 seconds to focus the window you want to target
set -eu

sleep 2
while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] && xdotool type --clearmodifiers --delay 60 -- "$line"
    xdotool key --clearmodifiers Return
    sleep 0.3
done < "${1:-/dev/stdin}"
```

## Conclusion

Starting OpenSSH from the FreeBSD installation media only takes a little work,
but I am glad I finally took the time to document these steps for future me.
