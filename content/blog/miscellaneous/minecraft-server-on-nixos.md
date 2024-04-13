---
title: Deploying a Minecraft bedrock server on NixOS
description: How I made this work for my niece
date: 2024-04-13
tags:
- Minecraft
- nix
---

## Introduction

My niece wanted to play Minecraft with me and her dad over the easter holiday. I feel that the realms official hosting are a bit expensive at 10€/month and not very flexible regarding pausing the subscription without losing your progress. We will probably stop playing when my niece has school only to pick up the game over the summer, so self hosting the game sounds a lot better.

## Self hosting Minecraft bedrock

### Deploying Minecraft

Minecraft bedrock is really not made for things other than consoles or phones. The good thing is that some clever people made it run anyway, the bad thing is that it requires some tricks.

I settled on using the [itzg/minecraft-bedrock-server](https://hub.docker.com/r/itzg/minecraft-bedrock-server) docker image with which I did not encounter any major problems. The only small issue I faced was during a Minecraft version update, for almost 48h I could not match the versions on the server, my niece's switch and my brother's PS5... but it solved itself when all devices finally agreed to be on the new release.

### Resolving bedrock user names to user ids

Since my niece is only eleven I wanted to lock down the server. This required finding out the Microsoft Xbox ids of each account and the main difficulty was that most guides focus on the Java version of Minecraft which relies on incompatible ids. To resolve your Xbox ids, use [this site](https://www.cxkes.me/xbox/xuid).

### Making the server reachable from consoles

One issue is that my niece plays on Nintendo Switch and cannot join custom servers with an IP address. I had to do some DNS shenanigans! The gist of it is that the only servers she can join are five especially "featured" servers. The console finds the IP addresses of these servers from hard coded hostnames, so by deploying my own DNS server and configuring the console to use it... I can answer my own server's IP address to one of these queries.

### Minecraft on NixOS

Here is the module I wrote to deploy the Minecraft container, the DNS tricks server and Borg backups:
```nix
{ config, pkgs, ... }:
{
  environment = {
    etc = {
      "borg-minecraft-data.key" = {
        mode = "0400";
        source = ./borg-data.key;
      };
    };
  };
  networking.firewall.allowedUDPPorts = [
    53 # DNS
    19132 # Minecraft
  ];
  services = {
    borgbackup.jobs = let defaults = {
      compression = "auto,zstd";
      doInit = true;
      encryption.mode = "none";
      prune.keep = {
        daily = 14;
        weekly = 4;
        monthly = 3;
      };
      startAt = "daily";
    }; in {
      "minecraft-data" = defaults // {
        environment.BORG_RSH = "ssh -i /etc/borg-minecraft-data.key";
        paths = "/srv/minecraft/worlds";
        repo = "ssh://borg@dalinar.adyxax.org/srv/borg/minecraft-data";
      };
    };
    unbound = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        server = {
          access-control = [ "0.0.0.0/0 allow" "::/0 allow" ];  # you might now want this open for recursion for everyone
          interface = [ "0.0.0.0" "::" ];
          local-data = "\"mco.lbsg.net. 10800 IN A X.Y.Z.T\"";  # one of the hardcoded hostnames on the console
          local-zone = "mco.lbsg.net. static";
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = "1.1.1.1"; #cloudflare dns";  # I still want the console to be able to resolve other domains
          }
        ];
      };
    };
  };
  virtualisation.oci-containers.containers = {
    minecraft = {
      environment = {
        ALLOW_CHEATS = "true";
        EULA = "TRUE";
        DIFFICULTY = "1";
        SERVER_NAME = "My Server";
        TZ = "Europe/Paris";
        VERSION = "LATEST";
        ALLOW_LIST_USERS = "adyxax:2535470760215402,pseudo2:XXXXXXX,pseudo3:YYYYYYY";
      };
      image = "itzg/minecraft-bedrock-server";
      ports = ["0.0.0.0:19132:19132/udp"];
      volumes = [ "/srv/minecraft/:/data" ];
    };
  };
}
```

Note that the `X.Y.Z.T` in the configuration is the IP address from which Minecraft is reachable.

## Conclusion

We had quite a lot of fun with this over the holiday, and I am pleased that Minecraft is so lightweight. It should run fine on a 3$/month VPS even in the late game! If you want to host a Minecraft server I recommend giving this a try.
