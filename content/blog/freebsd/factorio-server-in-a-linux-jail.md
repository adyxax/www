---
title: Running a Factorio server in a linux jail, on FreeBSD
description: How to setup a linux jail on FreeBSD using vanilla tools
date: 2022-11-13
tags:
- Factorio
- FreeBSD
- jail
---

## Introduction

Two weeks ago I started playing [factorio](https://www.factorio.com/) again with a friend. Factorio packages a dedicated server build for linux, but none of my linux vps' could afford the GB of ram to run factorio along their existing workloads. Therefore I settled on trying to run it inside a linux jail.

I had been meaning to test linux jails for quite some time but never had a good excuse to do it. This was the perfect opportunity!

## Preparing FreeBSD

### Linux subsystem

Normally FreeBSD 13 has all you need from the get go, we just need to load a few kernel modules and prepare some mount points. All this is abstracted away with:
```sh
service linux enable
service linux start
```

### Jail loopback interface

I strive for the simplest setup and this jail just needs the legacy loopback interface way of doing things:
```sh
echo "cloned_interfaces=\"lo1\"" >> /etc/rc.conf
service netif cloneup
```

Many jail tutorials will tell you to configure the jail ips in `/etc/rc.conf` too, this is not what I do. It is difficult to automate and I find that having those ips in the jails.conf file is a lot more flexible.

### pf firewall

Here is a template of my `/etc/pf.conf`:
```cfg
scrub in all

table <jails>    persist
table <myself>   const { self }
table <private>  const { 10/8, 172.16/12, 192.168/16, fd00::/8 fe80::/10 }
table <internet> const { 0.0.0.0/0, !10/8, !172.16/12, !192.168/16, ::/0, fe80::/10, !fd00::/8 }

##### Basic rules #####
nat  pass  on  egress  from  <jails>  to  <internet>  ->  (egress:0)
rdr-anchor "rdr/*"
set skip on lo
block return log

##### This firewall #####
block drop in on egress
pass inet proto icmp all icmp-type unreach code needfrag  # MTU path discovery
pass inet proto icmp all icmp-type { echoreq, unreach }   # echo reply
pass inet6 proto icmp6 all

pass in on egress proto tcp from <internet> to <myself> port { ssh, http, https }
pass out from <myself> to any

##### VPNs #####
pass in on egress proto udp from <internet> to <myself> port 342
pass in on wg0 from <private> to <myself>
pass in on wg0 from <private> to <private>
pass out on wg0 from <private> to <private>
```

The important lines are the one about the persistent `jails` table and the first two basic rules to `nat` egress jail traffic and process the `rdr-anchor` that will allow the ingress traffic.

## Bootstrapping the jail

For some reason, the debootstrap program installs itself without exec permission, and does not list bash as one of its dependencies.
```sh
pkg install  bash  debootstrap
```

I keep my jails under `/jails` and choose debian 11 bullseye:
```sh
bash  /usr/local/sbin/debootstrap
        --include=openssh-server,locales,rsync,sharutils,psmisc,patch,less,apt \
        --components main,contrib  bullseye  /jails/factorio
```

We need to mount the linux filesystems inside the jail:
```sh
echo "
linprocfs  /jails/factorio/proc  linprocfs  rw  0 0
linsysfs   /jails/factorio/sys   linsysfs   rw  0 0" >> /etc/fstab
mount -a
```

Setup a dedicated user to run factorio:
```sh
chroot /jails/factorio/ useradd -d /home/factorio -m -r factorio
```

Convert the linux password file into a bsd authentication database:
```sh
cat /jails/factorio/etc/passwd | sed -r 's/(:[x|*]:)([0-9]+:[0-9]+:)/:*:\2:0:0:/g' > /jails/factorio/etc/master.passwd
pwd_mkdb -p -d /jails/factorio/etc /jails/factorio/etc/master.passwd
```

## Installing factorio

The following downloads the factorio headless server and decompress it into `/jails/factorio/home/factorio`
```sh
wget https://dl.factorio.com/releases/factorio_headless_x64_1.1.70.tar.xz
(cd /jails/factorio/home/factorio/; tar xf /root/factorio_headless_x64_1.1.70.tar.xz)
mkdir /jails/factorio/home/factorio/factorio/saves/
```

Upload your save file from the game (or create a new map for the occasion) and place it into `/jails/factorio/home/factorio/factorio/saves/`.

If you want to use mods, now is the time to upload those into `/jails/factorio/home/factorio/factorio/mods`. A simple rsync of the mods folder from your game should do nicely.

Edit `/jails/factorio/home/factorio/factorio/config/server-settings.json` to your liking. For example, my server is not publicly visible and has a game password.

Let's not forget to assign the correct permissions after all this:
```sh
chroot /jails/factorio/ chown -R factorio:factorio /home/factorio
```

## Configuring the jail

Here is my `/etc/jail.conf.d/factorio.conf`:
```cfg
factorio {
        host.hostname = "factorio";
        path = /jails/$name;
        ip4.addr = 127.0.1.1/32;
        ip6 = "new";
        ip6.addr = fc00::1/128;
        exec.system_user = "root";
        exec.jail_user = "root";
        exec.clean;
        exec.prestart = "ifconfig lo1 alias ${ip4.addr}";
        exec.prestart += "ifconfig lo1 inet6 ${ip6.addr}";
        exec.prestart += "/sbin/pfctl -t jails -T add ${ip4.addr}";
        exec.prestart += "/sbin/pfctl -t jails -T add ${ip6.addr}";
        exec.prestart += "echo \"rdr pass on egress inet proto udp from any to port 34197 -> ${ip4.addr}\n  rdr pass on egress inet6 proto udp from any to port 34197 -> ${ip6.addr}\" | pfctl -a rdr/jail-$name -f -";
        exec.poststop = "/sbin/pfctl -t jails -T del ${ip4.addr}";
        exec.poststop += "/sbin/pfctl -t jails -T del ${ip6.addr}";
        exec.poststop += "pfctl -a rdr/jail-$name -F nat";
        exec.poststop += "ifconfig lo1 inet ${ip4.addr} -alias";
        exec.poststop += "ifconfig lo1 inet6 ${ip6.addr} -alias";
        exec.start = "/bin/su - factorio -c 'factorio/bin/x64/factorio --start-server factorio/saves/mysave.zip' &";
        exec.stop = "pkill factorio ; sleep 15";
        mount.devfs;
}
```

Make sure you substitute `mysave.zip` with the name of your save file!

As you can see, I use the `prestart` and `poststop` steps to handle the network configuration using `ifconfig`, the jails' pf table and the rdr port forwarding. These are all setup when starting the jail and cleaned when stopping.

## Final step

Now if all went according to plan, the following should be enough to start your factorio server in the jail:
```sh
service jail enable
service jail start factorio
```

Check that factorio is running using `top -j factorio`. If something goes wrong, you should be able to check `/jails/factorio/home/factorio/factorio/factorio-current.log` for clues. If this file was not created check the permissions on the facorio folders.

If everything is running, you should be able to connect to your dedicated server using the hostname of your server!
