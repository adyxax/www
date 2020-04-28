---
title: "Installation"
linkTitle: "installation"
weight: 1
description: >
  Installation of a gentoo system
---

## Installation media

You can get a bootable iso or liveusb from https://www.gentoo.org/downloads/. I recommend the minimal one. To create a bootable usb drive juste use `dd` to copy the image on it. Then boot on this brand new installation media.

Once you boot on the installation media, you can start sshd and set a temporary password and proceed with the installation more confortably from another machine :

{{< highlight sh >}}
/etc/init.d/sshd start
passwd
{{< /highlight >}}

## Partitionning

There are several options depending on wether you need soft raid, full disk encryption or a simple root device with no additional complications. It will also differ if you are using a virtual machine or a physical one.

{{< highlight sh >}}
fdisk /dev/sda
g
n
1
2048
+2M
t
1
4

n
2
6144
+512M
t
2
1

n
3
1054720

w
mkfs.ext4 /dev/sda3
mkfs.fat -F 32 -n efi-boot /dev/sda2
mount /dev/sda3 /mnt/gentoo
{{< /highlight >}}

## Get the stage3 and chroot into it

Get the stage 3 installation file from https://www.gentoo.org/downloads/. I personnaly use the non-multilib one from the advanced choices, since I am no longer using and 32bits software except steam, and I use steam from a multilib chroot.

Put the archive on the server in /mnt/gentoo (you can simply wget it from there), then extract it :
{{< highlight sh >}}
tar xpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
mount /dev/sda2 boot
mount -t proc none proc
mount -t sysfs none sys
mount -o rbind /dev dev
cp /etc/resolv.conf etc/
chroot .
{{< /highlight >}}

## Initial configuration

We prepare the local language of the system :
{{< highlight sh >}}
env-update && source /etc/profile
echo 'LANG="en_US.utf8"' > /etc/env.d/02locale
sed '/#en_US.UTF-8/s/#//' -i /etc/locale.gen
locale-gen
source /etc/profile
{{< /highlight >}}

We set a loop device to hold the portage tree. It will be formatted with optimisation for the many small files that compose it :
{{< highlight sh >}}
mkdir -p /srv/gentoo-distfiles
truncate -s 10G /portage.img
mke2fs  -b 1024 -i 2048 -m 0 -O "dir_index" -F /portage.img
tune2fs -c 0 -i 0 /portage.img
mkdir /usr/portage
mount -o loop,noatime,nodev /portage.img /usr/portage/
{{< /highlight >}}

We set default compilation options and flags. If you are not me and cannot rsync this location, you can browse it from https://packages.adyxax.org/x86-64/etc/portage/ :
{{< highlight sh >}}
rsync -a --delete packages.adyxax.org:/srv/gentoo-builder/x86-64/etc/portage/ /etc/portage/
sed -i /etc/portage/make.conf -e s/buildpkg/getbinpkg/
echo 'PORTAGE_BINHOST="https://packages.adyxax.org/x86-64/packages/"' >> /etc/portage/make.conf
{{< /highlight >}}

We get the portage tree and sync the timezone
{{< highlight sh >}}
emerge --sync
{{< /highlight >}}

## Set hostname and timezone

{{< highlight sh >}}
export HOSTNAME=XXXXX
sed -i /etc/conf.d/hostname -e /hostname=/s/=.*/=\"${HOSTNAME}\"/
echo "Europe/Paris" > /etc/timezone
emerge --config sys-libs/timezone-data
{{< /highlight >}}

## Check cpu flags and compatibility

TODO
{{< highlight sh >}}
emerge cpuid2cpuflags -1q
cpuid2cpuflags
gcc -### -march=native /usr/include/stdlib.h
{{< /highlight >}}

## Rebuild the system

{{< highlight sh >}}
emerge --quiet -e @world
emerge --quiet dosfstools app-admin/logrotate app-admin/syslog-ng app-portage/gentoolkit dev-vcs/git bird openvpn htop net-analyzer/tcpdump net-misc/bridge-utils sys-apps/i2c-tools sys-apps/pciutils sys-apps/usbutils sys-boot/grub sys-fs/ncdu sys-process/lsof
{{< /highlight >}}

## Grab a working kernel

Next we need to Grab a working kernel from our build server along with its modules. If you don't have one already, you have some work to do!

Check the necessary hardware support with :
{{< highlight sh >}}
i2cdetect -l
lspci -nnk
lsusb
{{< /highlight >}}

TODO specific page with details on how to build required modules like the nas for example.
{{< highlight sh >}}
emerge gentoo-sources genkernel -q
...
{{< /highlight >}}

## Final configuration steps

### fstab

{{< highlight sh >}}
# /etc/fstab: static file system information.
#
#<fs>         <mountpoint>  <type>  <opts>              <dump/pass>
/dev/vda3     /             ext4    noatime             0  1
/dev/vda2     /boot         vfat    noatime             1  2
/portage.img  /usr/portage  ext2    noatime,nodev,loop  0  0
{{< /highlight >}}

### networking
{{< highlight sh >}}
echo 'hostname="phoenix"' > /etc/conf.d/hostname
echo 'dns_domain_lo="adyxax.org"
config_eth0="192.168.1.3 netmask 255.255.255.0"
routes_eth0="default via 192.168.1.1"' > /etc/conf.d/net
cd /etc/init.d
ln -s net.lo net.eth0
rc-update add net.eth0 boot
{{< /highlight >}}

### Grub

TODO especially the conf in /etc/default/grub when using an encrypted /
{{< highlight sh >}}
{{< /highlight >}}

### /etc/hosts

{{< highlight sh >}}
scp root@collab-jde.nexen.net:/etc/hosts /etc/
{{< /highlight >}}

### root account access

{{< highlight sh >}}
mkdir -p /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDN1ha6PFKgxF3MSWUlDaruVVpj3UzoiN4IJEvDrCnDbIW8xu+TclbeGJSRXXBbqRKeUfhX0GDA7cvSUIAz2U7AGK7wq5tbzJKagVYtxcSHBSi6dZR9KGb3eoshnrCeFzem1jWXG02PZJGvjB+ml3QhUguyAqm9q0n/NL6zzKhGoKiELO+tQghGIY8jafRv4rE4yyXZnwuCu8JI9P8ldGhKgOPeOdKIVTIVezUmKILWgAF+Hg7O72rQqUua9sdoK1mEYme/wgu0bQbvN26owGgBAgS3uc2nngLD01TZToG/wC1wH9A3KxT6+3akjRlPfLOY0BuK4OBGEGm6e0KZrIMhUr8fHQ8nmTmBqw7puI0gIXYB2EjhpsQ7TijYVqLYXbyxaXYyqisgY0QRWC7Te5Io6TSgorfXzi7zrcQGgWByHkhxTylf36LYSKWEheIQIRqytOdGqeXagFMz2ptLFKk4dA61LS5fPXIJucdghvnmLPml8cO9/9VHQ7gq7DxQu7sIwt/W13yTTUyI9DSHwxeHUwECzxAb5pOVL6pRjTMH8q1/eAMl35TFSh6s5tGvvHGz9+gMlE9A2Pv8CyXDBmXV6srrwxTSlglnmgdq6c9w3VtBKu572/z0cS6vqZMgEno4rIiwyhqNWdjbMXYw/U0q/w5XC9zCcSuluxvaY14qqQ== adyxax
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMdBAFjENiPMTtq90GT3+NZ68nfGxQiRExaYYnLzm1ecmulCvsuA4AOpeLY6f+FWe+ludiw7nhrXzssDdsKBy0QL+XQyvjjjW4X+k9MYhP1gAWXEOGJnjJ/1ovEsMt++6fLyNKLUTA46kErbEehDs22r+rIiEKatrn0BNrJcRI94H44oEL1/ImzVam0cSBL0tPiaJxe60sBs7M76zfyFtVdMGkeuBpS7ee+FLA58fsS3/sEZmkas8MT0QdvZz1y/66MknXYbIaqDSOUACXGF4yVKpogLRRJ1SgNo1Ujo/U3VOR1O4CiQczsZOcbSdjgl0x3fJb7BaIxrZy9iW2I7G/L/chfTvRws+x1s1y5FNZOOiXMCdZjhgLaRwb6p5gMsMVn9sJbhDjmejcAkBKQDkzbvxxhfVkH225FoVXA9YF0msWLyOEyZQYbA8autLDJsAOT5RDfw/G82DQBufAPEBR/bPby0Hl5kjqW75bpSVxDvzmKwt3EpITg9iuYEhvYZ/Zq5qC1UJ54ZfOvaf0PsTUzFePty6ve/JzfxCV1XgFQ+B8l4NSz11loDfNXSUngf7lL4qu5X4aN6WmLFO1YbyFlfpvt3K1CekJmWVeE5mV9EFTUJ4ParVWRGiA4W+zaCOsHgRkcGkp4eYGyWW8gOR/lVxYU2IFl9mbMrC9bkdRbQ== hurricane' > /root/.ssh/authorized_keys
passwd
{{< /highlight >}}

### Add necessary daemons on boot
{{< highlight sh >}}
rc-update add syslog-ng default
rc-update add cronie default
rc-update add sshd default
{{< /highlight >}}

## TODO

{{< highlight sh >}}
net-firewall/shorewall
...
rc-update add shorewall default
sed '/PRODUCTS/s/=.*/="shorewall"/' -i /etc/conf.d/shorewall-init
rc-update add shorewall-init boot

net-analyzer/fail2ban
echo '[sshd]
enabled  = true
filter = sshd
ignoreip = 127.0.0.1/8  10.1.0.0/24  37.187.103.36  137.74.173.247  90.85.207.113
bantime  = 3600
banaction = shorewall
logpath = /var/log/messages
maxretry = 3' > /etc/fail2ban/jail.d/sshd.conf
rc-update add fail2ban default

app-emulation/docker
/etc/docker/daemon.json
{ "iptables": false }
rc-update add docker default

app-emulation/lxd
rc-update add lxd default
{{< /highlight >}}

## References

- http://blog.siphos.be/2013/04/gentoo-protip-using-buildpkgonly/
- https://wiki.gentoo.org/wiki/Genkernel
- https://wiki.gentoo.org/wiki/Kernel/Configuration
- https://wiki.gentoo.org/wiki/Kernel
- https://forums.gentoo.org/viewtopic-t-1076024-start-0.html
- https://wiki.gentoo.org/wiki/Binary_package_guide#Setting_up_a_binary_package_host
