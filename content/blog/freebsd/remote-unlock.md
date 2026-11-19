---
title: "Encrypted root on ZFS FreeBSD with an SSH unlock rescue system"
description: "How I install FreeBSD nowadays"
date: "2026-11-19"
tags:
- FreeBSD
---

## Introduction

This article explains how I setup FreeBSD systems nowadays. My use case is
mostly to have a FreeBSD rescue handy at cheap VPS providers that do not
natively support FreeBSD, and protect my data against providers that might not
properly erase disks when I stop using a VPS. Remote unlock over SSH is for
convenience.

This is achieved by creating a small unencrypted ZFS pool that holds /boot and a
minimal FreeBSD system that will be called the outerbase in this article. On
boot, I SSH into it and unlock the GELI partition of the main system and then
perform a soft reboot into it.

## Bootstrap the FreeBSD installer on a local virtual machine

Create the RAW hard drive image for your virtual machine. Using the minimal
necessary size will speed up later image transfer if it needs uploading to some
VPS or cloud provider. At the time of this writing, a minimal system seems to
fit in about 4GB, but feel free to use a bigger image if you do not intend to
transfer it later.

``` shell
qemu-img create -f raw ~/freebsd.raw 4G
```

Download the installer image from [an official
mirror](https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/15.1/)
then start up the installer in the virtual machine.

I start a UEFI virtual machine with something like:

``` shell
qemu-system-x86_64 \
    -drive if=none,id=disk,file=$HOME/freebsd.raw,format=raw,cache=writeback \
    -bios /usr/share/edk2/OvmfX64/OVMF_CODE.fd \
    -cpu host -smp 2 -m 4096 \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22,hostfwd=tcp::10023-:2222 \
    -device virtio-blk-pci,drive=disk \
    -device virtio-serial-pci \
    -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
    -vga qxl -spice port=5902,addr=127.0.0.1,disable-ticketing=on \
    -chardev spicevmc,id=spicechannel0,name=vdagent \
    -boot d -machine type=q35,accel=kvm \
    -cdrom $HOME/Downloads/FreeBSD-15.1-RELEASE-amd64-bootonly.iso
```

If you are short on memory, tune down the `-m 4096` flag that configures the
amount allocated to the virtual machine.

This virtual machine starts up with a SPICE display device, which I like better
than VNC, and can be accessed with a SPICE client like `spicy`. If you would
rather use VNC instead, replace the lines mentioning SPICE with the following to
start a VNC server on port 5900:

``` shell
    -display vnc=127.0.0.1:0 \
    -vga none -device virtio-vga,edid=on,xres=2560,yres=1440
```

Select `Shell` on the first installer menu screen, then set up the network
however is appropriate in your situation. At this point I like to [set up
OpenSSH]({{< ref "installer-ssh.md" >}}) so that I can copy and paste at my
leisure in a true terminal instead of a SPICE or VNC one.

## Prepare the disk

Partition the disk with:

``` shell
DISK=/dev/vtbd0
gpart create -s gpt $DISK
```

If you are preparing the disk for a UEFI VPS provider, continue the partitioning
process with:

``` shell
gpart add -a 1m -s 260m -t efi         -l efi    $DISK   # p1 EFI
gpart add -a 1m -s 1g   -t freebsd-zfs -l unlock $DISK   # p2 unencrypted unlocker
gpart add -a 1m         -t freebsd-zfs -l zroot  $DISK   # p3 encrypted root
newfs_msdos -F 32 -c 1 ${DISK}p1
mount_msdosfs ${DISK}p1 /mnt
mkdir -p /mnt/EFI/BOOT
cp /boot/loader.efi /mnt/EFI/BOOT/BOOTX64.EFI
umount /mnt
```

If you are preparing for a BIOS VPS provider instead, continue with:

``` shell
gpart add -a 4k -s 512k -t freebsd-boot -l boot   $DISK   # p1 gptzfsboot
gpart add -a 1m -s 1g   -t freebsd-zfs  -l unlock $DISK   # p2 unencrypted unlocker
gpart add -a 1m         -t freebsd-zfs  -l zroot  $DISK   # p3 encrypted root
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 $DISK
```

Then create the encrypted space with:

``` shell
geli init -e AES-XTS -l 256 -s 4096 /dev/gpt/zroot
geli attach /dev/gpt/zroot
```

Now we prepare ZFS for the main system:

``` shell
zpool create \
      -O acltype=posixacl \
      -O atime=off \
      -O compression=zstd-fast \
      -O mountpoint=none \
      -O relatime=on \
      -O xattr=sa \
      -o altroot=/mnt \
      -o ashift=12 \
      -o autoexpand=on \
      -o autotrim=on \
      -m none zroot /dev/gpt/zroot.eli
zfs create zroot/system
zfs create zroot/system/ROOT
zfs create -o mountpoint=/ -o canmount=noauto zroot/system/ROOT/default
zfs mount zroot/system/ROOT/default
zfs create -o mountpoint=/tmp                         -o setuid=off zroot/system/tmp
zfs create -o mountpoint=/usr                                       zroot/system/usr
zfs create -o mountpoint=/usr/local                   -o setuid=off zroot/system/usr/local
zfs create -o mountpoint=/usr/ports                   -o setuid=off zroot/system/usr/ports
zfs create -o mountpoint=/usr/src                     -o setuid=off zroot/system/usr/src
zfs create -o mountpoint=/var             -o exec=off -o setuid=off zroot/system/var
zfs create -o mountpoint=/var/db          -o exec=off -o setuid=off zroot/system/var/db
zfs create -o mountpoint=/var/spool       -o exec=off -o setuid=off zroot/system/var/spool
zfs create -o mountpoint=/var/tmp         -o exec=off -o setuid=off zroot/system/var/tmp
zfs create zroot/data
zfs create -o mountpoint=/home            -o exec=off -o setuid=off zroot/data/home
zfs create -o mountpoint=/home/julien                 -o setuid=off zroot/data/home/julien
zfs create -o mountpoint=/root                        -o setuid=off zroot/data/home/root
zfs create -o canmount=off                                          zroot/data/var
zfs create -o canmount=off                                          zroot/data/var/db
zfs create -o mountpoint=/var/db/postgres -o exec=off -o setuid=off zroot/data/var/db/postgres
zfs create -o mountpoint=/var/log         -o exec=off -o setuid=off zroot/data/var/log
chmod 1777 /mnt/tmp /mnt/var/tmp
zpool set bootfs=zroot/system/ROOT/default zroot
```

And then we prepare ZFS for the outerbase rescue system:

``` shell
zpool create \
      -O acltype=posixacl \
      -O atime=off \
      -O compression=zstd-fast \
      -O mountpoint=none \
      -O relatime=on \
      -O xattr=sa \
      -o altroot=/mnt/unlock \
      -o ashift=12 \
      -o autoexpand=on \
      -o autotrim=on \
      -m none broot /dev/gpt/unlock
zfs create -o mountpoint=/ -o canmount=noauto broot/unlock
zpool set bootfs=broot/unlock broot
mkdir -p /mnt/unlock
zfs mount broot/unlock
```

We want the main system's `/boot` to point to the outerbase one, and the symlink
needs to be written in such a way that it resolves correctly both during this
installation, and from the main system:

``` shell
mkdir -p /mnt/unlock/boot
ln -s unlock/boot /mnt/boot
```

With this done, the main system can install its kernel into the outerbase
system.

## Install FreeBSD

Let's bootstrap the package manager configurations of both the main and the
outerbase systems to use `latest` instead of `quarterly`, and enable PkgBase
like so:

``` shell
for R in /mnt /mnt/unlock; do
    mkdir -p $R/etc/pkg $R/usr/local/etc/pkg/repos/
    sed -e s/quarterly/latest/g \
        -e 's/enabled: no/enabled: yes/g' \
        /etc/pkg/FreeBSD.conf > $R/usr/local/etc/pkg/repos/FreeBSD.conf
    mkdir -p $R/usr/share/keys
    cp -R /usr/share/keys/* $R/usr/share/keys/
done
```

We can then install the main system with:

``` shell
export ASSUME_ALWAYS_YES=yes
export TMPDIR=/mnt/tmp
pkg -r /mnt -R /mnt/usr/local/etc/pkg/repos update
pkg -r /mnt -R /mnt/usr/local/etc/pkg/repos install \
    FreeBSD-kernel-generic pkg \
    FreeBSD-set-base
```

We install the outerbase system with:

``` shell
pkg -r /mnt/unlock -R /mnt/unlock/usr/local/etc/pkg/repos update
pkg -r /mnt/unlock -R /mnt/unlock/usr/local/etc/pkg/repos install \
    FreeBSD-set-minimal \
    FreeBSD-ssh pkg
```

Let's generate a ZFS hostid and set it in both systems so that the pools are not
considered foreign:

``` shell
uuidgen > /mnt/etc/hostid
cp /mnt/etc/hostid /mnt/unlock/etc/hostid
```

Now we generate the SSH authorized_keys and host keys, and set a root password
for both systems with:

``` shell
for R in /mnt /mnt/unlock; do
    mkdir -p -m 700 $R/root/.ssh
    fetch -o $R/root/.ssh/authorized_keys https://git.adyxax.org/adyxax.keys
    chmod 600 $R/root/.ssh/authorized_keys
    mount -t devfs none $R/dev
    chroot $R ssh-keygen -A
    chroot $R passwd
    umount $R/dev
done
```

We configure the FreeBSD loader with:

``` shell
cat > /mnt/unlock/boot/loader.conf <<'EOF'
geom_eli_load="YES"
zfs_load="YES"
autoboot_delay="5"
EOF
```

If like me you want to keep the serial console accessible, add something like
this to your `loader.conf`:

``` shell
boot_multicons="YES"
boot_serial="YES"
comconsole_speed="115200"
console="comconsole,vidconsole,efi"
```

The outerbase system does not have much to do, I bootstrap it with:

``` shell
cat > /mnt/unlock/etc/rc.conf <<'EOF'
cron_enable="NO"
dumpdev="NO"
hostname="unlock"
network_interfaces="vtnet0"
sendmail_enable="NONE"
sshd_enable="YES"
syslogd_flags="-ss"
EOF
cat > /mnt/unlock/etc/start_if.vtnet0 <<'EOF'
dhclient vtnet0
EOF
: > /mnt/unlock/etc/fstab
echo "nameserver 1.1.1.1" > /mnt/unlock/etc/resolv.conf

echo "Port 2222" >> /mnt/unlock/etc/ssh/sshd_config
echo "PermitRootLogin without-password" >> /mnt/unlock/etc/ssh/sshd_config
```

I use the following small script to unlock the main system from the outerbase
one:

``` shell
mkdir -p /mnt/unlock/usr/local/bin/
cat > /mnt/unlock/usr/local/bin/unlock.sh <<'EOF'
#!/bin/sh
# Attach the encrypted root and reroot into it. Run over ssh or on console.
set -eu
DEV=/dev/gpt/zroot
POOL=zroot

geli status "${DEV##/dev/}.eli" >/dev/null 2>&1 || geli attach "$DEV"

# pick the BE that bectl/zpool bootfs says is active
zpool import -f -N "$POOL"
BE=$(zpool get -H -o value bootfs "$POOL")
zpool export "$POOL"

echo "rerooting into zfs:${BE}"
kenv vfs.root.mountfrom="zfs:${BE}"
exec reboot -r
EOF
chmod 700 /mnt/unlock/usr/local/bin/unlock.sh
```

The main system configuration has a tiny bit more to it:

``` shell
cat > /mnt/etc/rc.conf <<'EOF'
clear_tmp_enable="YES"
dumpdev="NO"
hostname="myth"
local_unbound_enable="YES"
moused_nondefault_enable="NO"
network_interfaces="vtnet0"
ntpd_enable="YES"
ntpd_sync_on_start="YES"
sendmail_enable="NONE"
sshd_enable="YES"
syslogd_flags="-ss"
zfs_enable="YES"
EOF

cat > /mnt/etc/start_if.vtnet0 <<'EOF'
dhclient vtnet0
EOF

cat > /mnt/etc/fstab <<'EOF'
# Device          Mountpoint  FStype  Options  Dump  Pass
broot/unlock      /unlock     zfs     rw       0     0
EOF

echo "PermitRootLogin without-password" >> /mnt/etc/ssh/sshd_config
```

Do any remaining configuration you need, and finish with:

``` shell
umount /mnt/unlock
zpool export broot
zpool export zroot
halt -p
```

To test your new installation, update the QEMU command to `-boot c` instead of
`d` (which points to the installer ISO) then start the virtual machine again. If
your kept my `hostfwd` NIC configuration, you should be able to SSH and unlock
your system with:

``` shell
ssh -p 10023 root@localhost unlock.sh
ssh -p 10022 root@localhost
```

After copying this minimal image to a VPS provider, you will want to resize the
disks with (update the disk to match what your provider exposes):

``` shell
gpart recover da0
gpart resize -i 3 -a 1m da0
zpool online -e zroot
```

## Conclusion

I have been using an outerbase rescue system on my FreeBSD hosted servers for a
few years already, and I really like how tidy this has become thanks to PkgBase!
