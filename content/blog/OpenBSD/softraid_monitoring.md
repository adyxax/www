---
title: OpenBSD softraid monitoring
date: 2021-04-30
description: How to properly check a software raid array on OpenBSD
tags:
  - OpenBSD
---

## Introduction

I have reinstalled my nas recently from gentoo to OpenBSD and was amazed once again at how elegant OpenBSD is. The softraid setup was simple thanks to the wonderful [faq](https://www.openbsd.org/faq/faq14.html#softraid). The only thing I changed is that I used a raid5 with 3 disks, but the last line of the faq about the monitoring left the matter as an exercise to the reader.

## Softraid monitoring

I had a hard time figuring out how to properly monitor the state of the array without relying on parsing the output of `bioctl` but at last here it is in all its elegance :
{{< highlight sh >}}
root@nas:~# sysctl hw.sensors.softraid0
hw.sensors.softraid0.drive0=online (sd4), OK
{{< /highlight >}}

I manually failed one drive (with `bioctl -O /dev/sd2a sd4`) then rebuilt it (with `bioctl -R /dev/sd2a sd4)`... then failed two drives in order to have examples of all possible outputs. Here they are if you are interested :
{{< highlight sh >}}
root@nas:~# sysctl hw.sensors.softraid0
hw.sensors.softraid0.drive0=degraded (sd4), WARNING
{{< /highlight >}}

{{< highlight sh >}}
root@nas:~# sysctl hw.sensors.softraid0
hw.sensors.softraid0.drive0=rebuilding (sd4), WARNING
{{< /highlight >}}

{{< highlight sh >}}
root@nas:~# sysctl -a |grep -i softraid
hw.sensors.softraid0.drive0=failed (sd4), CRITICAL
{{< /highlight >}}

## Nagios check

I am still using nagios on my personal infrastructure, here is the check I wrote if you are interested :

{{< highlight perl >}}
#!/usr/bin/env perl
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

use strict;
use warnings;

##### Arguments processing #####
use Getopt::Long;
my $diskname;
my $usage = "Usage: $0 [OPTIONS]
OPTIONS:
    -d DEVICE_NAME, --device-name=DEVICE_NAME : device name to inspect.";
GetOptions("device-name=s" => \$diskname) or die $usage;
die "You must provide a device-name\n\n$usage" unless $diskname;

##### Softraid Check #####
my %output = (
        "code" => 3,
        "status" => "UNKNOWN",
);
if (`uname` eq "OpenBSD\n") {
        $output{status} = $1 if `sysctl hw.sensors.$diskname.drive0` =~ /=(.*)$/ or do { $!=3; die "UNKNOWN Failed to get sysctl hw.sensors.$diskname.drive0" };
        $output{code} = 0 if ($output{status} =~ /OK$/);
        $output{code} = 1 if ($output{status} =~ /WARNING$/);
        $output{code} = 2 if ($output{status} =~ /CRITICAL$/);
}

print $output{status};
exit $output{code};
{{< /highlight >}}
