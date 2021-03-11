---
title: "Building rpm packages"
date: 2016-02-22
description: How to build locally an rpm package
tags:
  - Centos
  - rhel
---

## Setup your environment

First of all, you have to use a non-root account.

 - Create the necessary directories : `mkdir -p ~/rpmbuild/{BUILD,RPMS,S{OURCE,PEC,RPM}S}`
 - Tell rpmbuild where to build by adding the following in your `.rpmmacros` file : `echo -e “%_topdir\t$HOME/rpmbuild” » ~/.rpmmacros`

## Building package

There are several ways to build a rpm, depending on what kind of stuff you have to deal with.

### Building from a tar.gz archive containing a .spec file

Run the following on you .tar.gz archive : `rpmbuild -tb memcached-1.4.0.tar.gz`. When the building process ends, you will find your package in a `$HOME/rpmbuild/RPMS/x86_64/` like directory, depending on your architecture.

### Building from a spec file

 - `rpmbuild -v -bb ./contrib/redhat/collectd.spec`
 - If you are missing some dependencies : `rpmbuild -v -bb ./contrib/redhat/collectd.spec 2>&1 |awk '/is needed/ {print $1;}'|xargs yum install -y`
