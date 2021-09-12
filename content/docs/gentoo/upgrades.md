---
title: "Gentoo Packages Upgrades"
description: Gentoo packages upgrades on adyxax.org
tags:
- gentoo
- linux
---

## Introduction

Here is my go to set of commands when I upgrade a gentoo box :
{{< highlight sh >}}
emerge-webrsync
eselect news read
{{< /highlight >}}

The news have to be reviewed carefully and if I cannot act on it immediately I copy paste the relevant bits to my todolist.

## The upgrade process

I run the upgrade process in steps, the first one asking you to validate the upgrade path. You will also be prompted to validate before cleaning :
{{< highlight sh >}}
emerge -qAavutDN world --verbose-conflicts --keep-going --with-bdeps=y && emerge --depclean -a && revdep-rebuild -i -- -q --keep-going; eclean --deep distfiles && eclean --deep packages && date
{{< /highlight >}}

After all this completes it is time to evaluate configuration changes :
{{< highlight sh >}}
etc-update
{{< /highlight >}}

If a new kernel has been emerged, have a look at [the specific process for that]({{< ref "kernel_upgrades" >}}).

## Post-upgrade

Depending of the changes it is now time to :
- restart services that have been upgraded
- reboot if the kernel or a crucial system component (like openssl) has been upgraded
