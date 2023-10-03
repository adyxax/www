---
title: Installing nixos on a vps
description: A process that would also work for other operating systems
date: 2023-10-04
tags:
- nix
---

## Introduction

Not many providers consider nixos as a first class citizen, you need a little know how to be able to set it up in a not so friendly environment. Nixos's wiki has several procedures to achieve this but I found those either too complicated or not up to date. This article presents my prefered way to install an operating system somewhere it is not supported to do so, and it works for anything.

## Installation

### Prepare a virtual machine

If you followed [my last article]({{< ref "nixos-getting-started.md" >}}), you should have a nixos virtual machine ready to go. You just need to upload it somewhere. I chose kaladin.adyxax.org, another one of my machines, and to serve the machine over ssh. Alternatively you could use a web server or even socat/netcat if it strikes your fancy.

### Bootstrap your vps or compute instance

Install your vps or compute instance normally using a Linux distribution (or any of the BSD) that is supported by your provider. Connect to it as root.

### Remount disk partitions as read only

We are going to remount the partitions as the running OS as read only. In order to do that, we are going to shutdown nearly everything! If at some point you lose access to your system, just force reboot it and try again. Our goal is for those commands to run without an error:
```sh
mount -o remount,ro /boot
mount -o remount,ro /
```

If there are other disk partitions mounted, those must be remounted read only as well. Check `cat /proc/mounts` if you do not know what to look for.

Be aware that selinux could block you. If that is the case, deactivate it, reboot and start over.

On most Linux you can list running services using `systemctl|grep running` and begin running `systemctl stop` commands on almost anything, just remember to keep what your running session depends on:
- init
- session-XX
- user@0 (root) and any user@XX where XX is the uid you connected with

Everything else should be fair game, here is a list of what I shutdown on an oracle cloud compute before I could remount / read only:
```sh
systemctl stop smartd
systemctl stop rpcbind
systemctl stop rpcbind.socket
systemctl stop systemd-journald-dev-log.socket
systemctl stop systemd-journald.socket
systemctl stop systemd-udevd-control.socket
systemctl stop systemd-udevd-kernel.socket
systemctl stop tuned.service
systemctl stop user@1000.service
systemctl stop user@989.service
systemctl stop rsyslog
systemctl stop oswatcher.service
systemctl stop oracle-cloud-agent.service
systemctl stop oracle-cloud-agent-updater.service
systemctl stop gssproxy.service
systemctl stop crond.service
systemctl stop chronyd.service
systemctl stop auditd.service
systemctl stop atd.service
systemctl stop auditd.service
systemctl stop sssd
systemctl stop sssd_bd
systemctl stop firewalld
systemctl stop auditd
systemctl stop iscsid
systemctl stop iscsid.socket
systemctl stop dbus.socket
systemctl stop dbus
systemctl stop systemd-udevd
systemctl stop sshd
systemctl stop libstoragemgmt.service
systemctl stop irqbalance.service
systemctl stop getty@tty1.service
systemctl stop serial-getty@ttyS0.service
```

Remember, your success condition is to be able to run this without errors:
```sh
mount -o remount,ro /boot
mount -o remount,ro /
```

As soon as this is done and you only have `ro` in `cat /proc/mounts` for your disk partitions you can stop shutting down services.

### Copying the virtual machine you prepared

When successful at remounting your partitions read only, then retrieve your virtual machine image. You will need to copy it directly to the disk, here is how I do it using ssh:
```sh
ssh root@kaladin.adyxax.org "dd if=/nixos-uefi.raw" | dd of=/dev/sda
```

## Reboot and test

Once the copy is complete, you will have to force reboot your machine. After a minute you should be able to ssh to it and get a nixos shell!

You will need a virtual console or KVM of some sort to debug your image if something went wrong. All providers have this capability, you just have to find it in their webui.

## Conclusion

I used this procedure successfully on ovh, hetzner, google cloud and on oracle cloud and I believe it should work anywhere. I used it for nixos, but also to install some Gentoo, OpenBSD or FreeBSD where those were not supported either.
