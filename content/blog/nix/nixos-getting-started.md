---
title: Getting started with nixos
description: How to setup an UEFI compatible virtual machine running nixos
date: 2023-09-30
tags:
- nix
---

## Introduction

After discovering nix I quickly jumped into nixos, the Linux distribution based on nix. It has been a few months now and I very much like nixos's stability and reproducibility. Upgrades went smoothly each time and I migrated quite a few services to a nixos server.

## Installation

### Virtual machine bootstrap

Installing nixos is really not hard, you quickly get to a basic setup you can completely understand thanks to its declarative nature. When I began tinkering with nixos, my goal was to install it on a vps for which I needed UEFI support, here is how I bootstrapped a virtual machine locally:
```sh
qemu-img create -f raw nixos.raw 4G
qemu-system-x86_64 -drive file=nixos.raw,format=raw,cache=writeback \
                   -cdrom Downloads/nixos-minimal-23.05.1994.af8279f65fe-x86_64-linux.iso \
                   -boot d -machine type=q35,accel=kvm -cpu host -smp 2 -m 1024 -vnc :0 \
                   -device virtio-net,netdev=vmnic -netdev user,id=vmnic,hostfwd=tcp::10022-:22 \
                   -bios /usr/share/edk2-ovmf/OVMF_CODE.fd
```

### Partitioning

From there, I performed the following simple partitioning (just one big root partition):
```sh
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MB 100%
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### Initial configuration

The initial configuration is generated with:
```sh
nixos-generate-config --root /mnt
```

This will generate a `/mnt/etc/nixos/hardware-configuration.nix` with the specifics of your machine along with a basic `/mnt/etc/nixos/configuration.nix` that I replaced with:
```nix
{ config, pkgs, ... }:
{
	imports = [
		./hardware-configuration.nix
	];
	boot.kernelParams = [
		"console=ttyS0"
		"console=tty1"
		"libiscsi.debug_libiscsi_eh=1"
		"nvme.shutdown_timeout=10"
	];
	boot.loader = {
		efi.canTouchEfiVariables = true;
		systemd-boot.enable = true;
	};
	environment.systemPackages = with pkgs; [
		curl
		tmux
		vim
	];
	networking = {
		dhcpcd.enable = false;
		hostname = "dalinar";
		nameservers = [ "1.1.1.1" "9.9.9.9" ];
		firewall = {
			allowedTCPPorts = [ 22 ];
			logRefusedConnections = false;
			logRefusedPackets = false;
		};
		usePredictableInterfaceNames = false;
	};
	nix = {
		settings.auto-optimise-store = true;
		extraOptions = ''
			min-free = ${toString (1024 * 1024 * 1024)}
			max-free = ${toString (2048 * 1024 * 1024)}
		'';
		gc = {
			automatic = true;
			dates = "weekly";
			options = "--delete-older-than 30d";
		};
	};
	security = {
		doas.enable = true;
		sudo.enable = false;
	};
	services = {
		openssh = {
			enable = true;
			settings.KbdInteractiveAuthentication = false;
			settings.PasswordAuthentication = false;
		};
		resolved.enable = false;
	};
	systemd.network.enable = true;
	time.timeZone = "Europe/Paris";
	users.users = {
		adyxax = {
   			description = "Julien Dessaux";
   			extraGroups = [ "wheel" ];
   			hashedPassword = "$y$j9T$Nne7Ad1nxNmluCKBzBG3//$h93j8xxfBUD98f/7nGQqXPeM3QdZatMbzZ0p/G2P/l1";
   			home = "/home/julien";
   			isNormalUser = true;
   			openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco adyxax@yen" ];
   		};
   		root = {
   			hashedPassword = "$y$j8F$ummLlZmPdS1KGxSnwH8CY.$bjvADB9IdfwzO6/2if5Sl9DeCmCRdasknq4IJEAuxyA";
   			openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco adyxax@yen" ];
   		};
   	};
	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It's perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.05";
	# Copy the NixOS configuration file and link it from the resulting system
	# (/run/current-system/configuration.nix). This is useful in case you
	# accidentally delete configuration.nix.
	system.copySystemConfiguration = true;
}
```

This will setup a system that in particular will use the systemd-bootd boot loader in lieu of grub and systemd-networkd instead of NetworkManager. Not much else is going on. The nix section slows builds a bit but greatly reduced disk space consumption.

### Installation

```sh
nixos-install --no-root-passwd
```

### Rebooting

In order to boot on the newlly installed system and not the installer, the virtual machine command needs to be changed, so shutdown your system with:
```sh
halt -p
```

And start it with:
```sh
qemu-system-x86_64 -drive file=nixos.raw,format=raw,cache=writeback \
                   -boot c -machine type=q35,accel=kvm -cpu host -smp 2 -m 1024 -vnc :0 \
                   -device virtio-net,netdev=vmnic -netdev user,id=vmnic,hostfwd=tcp::10022-:22 \
                   -bios /usr/share/edk2-ovmf/OVMF_CODE.fd
```

## Updating the configuration

If you change the configuration, you need to rebuild the system with:
```sh
nixos-rebuild  switch
```

## Upgrading

You can rebuild your system with the latest nixos packages using:
```sh
nix-channel --update
nixos-rebuild  switch
```

## Conclusion

Installing and tinkering with nixos is quite fun! In the next articles I will explain how I organized my configurations to manage multiple servers, how to use a luks encrypted system and remotely unlock them after rebooting, and how to run the builds for small servers from a much more powerful machine.
