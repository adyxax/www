---
title: 'Installing FreeBSD 15 on any VPS'
date: '2026-05-29'
description: 'With encrypted root on ZFS'
tags:
  - 'FreeBSD'
  - 'QEMU'
---

## Introduction

Not many Virtual Private Server (VPS) providers consider FreeBSD a first-class
citizen, and few encourage you to encrypt your hard drive from inside the VPS.

Though encrypting a VPS hard drive does not protect against everything and
requires one to access the web KVM of the provider to type in a password on each
reboot, I still find it reassuring.

You need a little know-how to be able to set up FreeBSD in a not so friendly
environment. There are several procedures to achieve this floating around the
Internet, but I found those either too complicated or out of date. This article
presents my preferred way to install a FreeBSD operating system on a provider
that does not officially support it, and it works even for other unsupported
operating systems.

## Install a Linux system to inspect the pre-provisioned VPS

Depending on your provider, you will want to prepare either a BIOS boot image
(for example at OVH) or a UEFI boot image (for example on Azure or on Oracle
Cloud). One way to find out which one is to install any Linux image supported by
your provider and run:

``` shell
dmesg | grep -i "efi:"
```

If you see lines like the following, then you need to prepare a UEFI boot image.
Otherwise, prepare a BIOS boot image:

``` shell
[    0.000000] efi: EFI v2.7 by EDK II
[    0.000000] efi: SMBIOS=0xbbea9000 ACPI=0xbbf9c000 ACPI 2.0=0xbbf9c014 MEMATTR=0xba639518 MOKvar=0xbbe97000
```

## Bootstrap the FreeBSD installer on a local virtual machine

Create the RAW hard drive image for your virtual machine. Using the minimal
necessary size will speed up the later image transfer. At the time of this
writing, FreeBSD bootstraps fine on 1.6G of storage:

``` shell
qemu-img create -f raw freebsd.raw 1600M
```

Download the installer image from [an official
mirror](https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/15.0/FreeBSD-15.0-RELEASE-amd64-bootonly.iso)
then start up the installer in the virtual machine.

I start a BIOS booted virtual machine with something like:

``` shell
qemu-system-x86_64 \
    -drive if=none,id=disk,file=$PWD/freebsd.raw,format=raw,cache=writeback \
    -cdrom $HOME/Downloads/FreeBSD-15.0-RELEASE-amd64-bootonly.iso \
    -boot d -machine type=q35,accel=kvm \
    -cpu host -smp 2 -m 4096 \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22 \
    -device virtio-blk-pci,drive=disk \
    -device virtio-serial-pci \
    -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
    -vga qxl -spice port=5902,addr=127.0.0.1,disable-ticketing=on \
    -chardev spicevmc,id=spicechannel0,name=vdagent
```

To boot in UEFI mode instead, add the following line somewhere in the middle.
You might need to install another package and customize the path on your system,
this one is for Gentoo:

``` shell
    -bios /usr/share/edk2/OvmfX64/OVMF_CODE.fd \
```

If you are short on memory, tune down the `-m 4096` flag that configures the
amount allocated to the virtual machine.

This virtual machine starts up with a SPICE display device, which I like better
than VNC, and can be accessed with a SPICE client like `spicy`. If you would
rather use VNC instead, replace the lines mentioning SPICE with the following
to start a VNC server on port 5900:

``` shell
    -display vnc 127.0.0.1:0 \
    -vga none -device virtio-vga,edid=on,xres=2560,yres=1440
```

## Install FreeBSD

Proceed to install FreeBSD as you normally would. I personally switched to
`pkgbase` instead of the venerable distribution sets and am very happy with this
choice. For simple host setups like this with only one drive, I use the auto ZFS
partitioning mode. Make sure to choose the correct `Partitioning Scheme` and to
encrypt your disks if you wish to. I also disable swap at this point.

To type in passwords, either for disk encryption or for the root and user
accounts, the SPICE or VNC GUI can be unwieldy. When it is time for a password
prompt, I like to use `xdotool` to simulate the keyboard inputs, bypassing the
fact that copy/paste is not functional:

``` shell
read -rs pass
sleep 2; xdotool type -- "$pass"
unset pass
```

After pressing Enter to execute this command, I have two seconds to switch to
the SPICE or VNC window before the password is typed for me.

Once the installation is complete, shut down the virtual machine.

## Prepare the network configuration

Restart the virtual machine on the newly installed system by setting the boot
device to `c` and removing the ISO image flags. Make sure to keep the UEFI
setting if you need it!

``` shell
qemu-system-x86_64 \
    -drive if=none,id=disk,file=$PWD/freebsd.raw,format=raw,cache=writeback \
    -boot c -machine type=q35,accel=kvm \
    -cpu host -smp 2 -m 4096 \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22 \
    -device virtio-blk-pci,drive=disk \
    -device virtio-serial-pci \
    -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
    -vga qxl -spice port=5902,addr=127.0.0.1,disable-ticketing=on \
    -chardev spicevmc,id=spicechannel0,name=vdagent
```

Log in as root, then edit your `/etc/rc.conf`. You likely used DHCP for the
installation, but for most providers this needs to be customized for FreeBSD (in
particular if you want IPv6). I found that there are no general rules here: the
best indicator is to install a Linux system supported by your VPS provider and
inspect the pre-provisioned configuration.

For example on an OVH VPS, I set everything statically in a
`/etc/start_if.vtnet0`:

``` shell
ifconfig vtnet0 inet 37.187.244.19/32
route -4 add 37.187.244.1/32 -interface vtnet0
route -4 add default 37.187.244.1
ifconfig vtnet0 inet6 2001:41d0:401:3100::fd5/64
route -6 add default 2001:41d0:401:3100::1
```

But on Oracle Cloud Infrastructure, I use something like:

``` shell
ifconfig vtnet0 inet 10.0.0.62/24
route -4 add default 10.0.0.1
ifconfig vtnet0 inet6 2603:c022:c002:8500:e2a4:f02e:43b0:c1d8/64 accept_rtadv
```

You will have to figure out what you need based on the provider you chose.

## Boot the VPS in rescue mode and transfer the disk image

Most VPS providers offer a rescue mode that will boot your server on a Linux
image with diagnostic tooling. If yours does not offer that capability, maybe
you can do something similar by creating a second Linux server and attaching the
boot disk of the first one to it (that's what I did to get my FreeBSD image to
Oracle Cloud).

Whatever way you proceed, your first step is to identify what the `/dev` path of
the target block device is with `blkid` and `fdisk -l`. I will use `/dev/sdb` as
an example. Make sure your disk is not mounted anywhere (rescue modes love to do
that).

Once ready, completely erase your disk with `blkdiscard /dev/sdb`. If
`blkdiscard` is unsupported for some reason, you can skip it. Then copy over
your raw image. I usually copy it in place with a command like the following
(replace `myth.adyxax.org` with your actual server address):

``` shell
dd if="$PWD/freebsd.raw" | ssh root@myth.adyxax.org dd of=/dev/sdb
```

## First boot

Once the image has finished transferring, you should be able to disable rescue
mode (or shut down the temporary installation instance and reattach the boot
disk to your original instance if you went that route). Reboot your server to
enjoy your new FreeBSD system!

If you chose full disk encryption, or if anything goes wrong and you need to
debug the boot process, then the web KVM of your provider will be your best
friend.

## Resizing the root disk

I deliberately set up a very small virtual disk as to speed up transfer of the
resulting image. After booting into the new system, we will want to make use of
the full storage space allocated to the instance. When using FreeBSD with root
on ZFS, I first inspect the storage layout with these two commands:

``` shell
# gpart show -p
=>      40  41942960    da0  GPT  (20G)
        40      1024  da0p1  freebsd-boot  (512K)
      1064       984         - free -  (492K)
      2048  41940952  da0p2  freebsd-zfs  (20G)

# zpool status -P
  pool: zroot
 state: ONLINE
config:
	NAME              STATE     READ WRITE CKSUM
	zroot             ONLINE       0     0     0
	  /dev/da0p2.eli  ONLINE       0     0     0
```

I then do the resizing with something like:

``` shell
gpart recover da0
gpart resize -i 2 da0
geli resize /dev/da0p2
zpool online -e zroot /dev/da0p2.eli
```

## Conclusion

This method has served me well for years, and I am glad I finally took the time
to write the FreeBSD version of these instructions for future reference.
