---
title: "Install NixOS with root on ZFS"
description: Build a UEFI NixOS disk image with an encrypted ZFS root filesystem and remote initrd unlocking
date: 2026-08-30
tags:
  - NixOS
  - ZFS
---

## Introduction

I had some fun migrating my NixOS servers to root on ZFS a while ago but did not
take the time to write about it. This was mostly for fun and consistency with my
other setups because thanks to Nix, the operating system itself does not benefit
that much from being on ZFS. You can (almost) always revert to a previous
working state right from the boot loader entries, but ZFS still adds its usual
benefits for all the other parts: snapshots you can send remotely, zvols, native
encryption, native compression.

## Bootstrap the NixOS installer on a local virtual machine

Create the RAW hard drive image for your virtual machine. Using the minimal
necessary size will speed up later image transfer if it needs uploading to some
VPS or cloud provider. At the time of this writing, a minimal system seems to
fit in about 4GB, but feel free to use a bigger image if you do not intend to
transfer it later.

``` shell
qemu-img create -f raw nixos.raw 4G
```

Download the installer image from [an official
mirror](https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso)
then start up the installer in the virtual machine.

I start a UEFI virtual machine with something like:

``` shell
qemu-system-x86_64 \
    -bios /usr/share/edk2/OvmfX64/OVMF_CODE.fd \
    -drive if=none,id=disk,file=$PWD/nixos.raw,format=raw,cache=writeback \
    -cdrom $HOME/Downloads/nixos-minimal-26.05.6200.8623c4c20aa4-x86_64-linux.iso \
    -boot d -machine type=q35,accel=kvm \
    -cpu host -smp 2 -m 4096 \
    -nic user,model=virtio-net-pci,hostfwd=tcp::10022-:22,hostfwd=tcp::10023-:2222 \
    -device virtio-blk-pci,drive=disk \
    -device virtio-serial-pci \
    -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
    -vga qxl -spice port=5902,addr=127.0.0.1,disable-ticketing=on \
    -chardev spicevmc,id=spicechannel0,name=vdagent
```

If you are short on memory, tune down the `-m 4096` flag that configures the
amount allocated to the virtual machine.

This virtual machine starts up with a SPICE display device, which I like better
than VNC, and can be accessed with a SPICE client like `spicy`. If you would
rather use VNC instead, replace the lines mentioning SPICE with the following to
start a VNC server on port 5900:

``` shell
    -display vnc 127.0.0.1:0 \
    -vga none -device virtio-vga,edid=on,xres=2560,yres=1440
```

## Prepare the disk

Grab a shell using the spice or VNC connection, then set a password so that we
can SSH in instead:

``` shell
sudo passwd
```

Then if you did not change the host forwarded tcp port in the qemu command
above, you will be able to SSH in with:

``` shell
ssh -o UserKnownHostsFile=/dev/null -p10022 root@localhost
```

Partition the disk with:

``` shell
sgdisk -n1:0:+1G -t1:EF00 -c1:"EFI system partition" /dev/vda
sgdisk -n2:0:0 -t2:8300 -c2:ZROOT /dev/vda
```

I use the partition UUIDs for everything. They can be listed using the `blkid`
command. Format your partitions with:

``` shell
mkfs.fat -F 32 -n efi-boot /dev/disk/by-partuuid/cae9469a-c8ee-4c85-b86b-990dd6b7fb5b
zpool create \
      -O acltype=posixacl \
      -O atime=off \
      -O compression=zstd-fast \
      -O encryption=aes-256-gcm \
      -O keyformat=passphrase \
      -O keylocation=prompt \
      -O mountpoint=none \
      -O relatime=on \
      -O xattr=sa \
      -o ashift=12 \
      -o autoexpand=on \
      -o autotrim=on \
      -m none zroot /dev/disk/by-partuuid/80d4e8b7-c8af-41a9-b1c0-969a30d484cb
```

I create the following ZFS datasets in two groups: `system` which I do not
intend to snapshot, and `data` which I do. All mountpoints are marked as
`legacy` to let NixOS handle when to mount each filesystem during the boot
process:

``` shell
zfs create zroot/system
zfs create zroot/system/nixos
zfs create -o mountpoint=legacy zroot/system/nix
zfs create -o mountpoint=legacy zroot/system/tmp
zfs create -o mountpoint=legacy zroot/system/usr
zfs create -o mountpoint=legacy zroot/system/usr/local
zfs create -o mountpoint=legacy zroot/system/var-tmp
zfs create zroot/data
zfs create -o mountpoint=legacy zroot/data/home
zfs create -o mountpoint=legacy zroot/data/home/julien
zfs create -o mountpoint=legacy -o quota=1M zroot/data/home/root
zfs create -o mountpoint=legacy zroot/data/var
zfs create -o mountpoint=legacy zroot/data/var/log
```

Mount everything with:

``` shell
mount -t zfs -o zfsutil zroot/system/nixos /mnt
mkdir /mnt/{boot,home,nix,root,tmp,var}
mount /dev/disk/by-partuuid/cae9469a-c8ee-4c85-b86b-990dd6b7fb5b /mnt/boot
mount -t zfs zroot/data/home /mnt/home
mount -t zfs zroot/data/home/root /mnt/root
mount -t zfs zroot/system/nix /mnt/nix
mount -t zfs zroot/system/tmp /mnt/tmp
mount -t zfs zroot/data/var /mnt/var
mkdir /mnt/home/julien /mnt/usr /mnt/var/{log,tmp}
mount -t zfs zroot/data/home/julien /mnt/home/julien
mount -t zfs zroot/system/usr /mnt/usr
mount -t zfs zroot/data/var/log /mnt/var/log
mount -t zfs zroot/system/var-tmp /mnt/var/tmp
mkdir /mnt/usr/local
mount -t zfs zroot/system/usr/local /mnt/usr/local
```

## Install NixOS

With the disks prepared, we can generate the initial configuration with:

``` shell
nixos-generate-config --root /mnt
```

Edit `/mnt/etc/nixos/hardware-configuration.nix` and fix the following entries:

``` nix
fileSystems."/" = {
    device = "zroot/system/nixos";
    fsType = "zfs";
    options = [ "zfsutil" ];
};
fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/cae9469a-c8ee-4c85-b86b-990dd6b7fb5b";
    fsType = "vfat";
    options= ["umask=0077" "tz=UTC"];
};
```

Then in this same file, add:

``` nix
boot.zfs.forceImportRoot = true;
boot.zfs.requestEncryptionCredentials = true;
boot.zfs.devNodes = "/dev/disk/by-partuuid/80d4e8b7-c8af-41a9-b1c0-969a30d484cb";
```

Here is the rest of my not so minimal `configuration.nix` as an example. It
features remote ZFS unlocking via an SSH server embedded in the initrd:

``` nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = [
            "ssh-ed25519 AAAAC3szaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco julien"
          ];
        };
      };
      systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };
    kernelParams = [
      "console=ttyS0"
      "console=tty0"
      "console=tty1"
      "nvme.shutdown_timeout=10"
      "libiscsi.debug_libiscsi_eh=1"
      "ip=dhcp"
    ];
    loader.systemd-boot.consoleMode = "auto";
  };
  environment.systemPackages = with pkgs; [
    bmon
    curl
    dig
    gitMinimal
    gnumake
    gptfdisk
    mosh
    mtr
    ncdu
    parted
    tcpdump
    tmux
    tree
    vim
  ];
  users.users.root = {
    hashedPassword = "$y$j9T$umxLlXmPdS0KGxSnrH9CY.$bjvADE7IdfwgO6/1ii5Sl8DeBpCRdasknq3IJEAuxyA";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3szaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco julien"
    ];
  };
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPortRanges = [
        { from = 60000; to = 60100; } # mosh
      ];
      logRefusedConnections = false;
      logRefusedPackets = false;
    };
    hostId = "8425e349";  # ZFS hostId
    hostName = "vin";
    usePredictableInterfaceNames = false;
  };
  systemd.network.enable = true;
  nix = {
    extraOptions = ''
        min-free = ${toString (1024 * 1024 * 1024)}
        max-free = ${toString (2048 * 1024 * 1024)}
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };
  services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  virtualisation.podman.defaultNetwork.settings = {
    ipv6_enabled = true;
    subnets = [
      { gateway = "10.88.0.1"; subnet = "10.88.0.0/16"; }
      { gateway = "fd42::1"; subnet = "fd42::/48"; }
    ];
  };

  environment = {
    etc."tmux.conf" = {
      mode = "0444";
      source = ./tmux.conf;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
```

Install with:

``` shell
nixos-install --no-root-password
```

## Conclusion

ZFS on NixOS works really well, I recommend giving it a try!
