---
title: "irc"
description: irc.adyxax.org private chat server
---

## Introduction

I have been hosting a private irc chat server since 2009 for myself and some geek friends. It is a simple standalone [ngircd](https://ngircd.barton.de/) server, no backups necessary.

There is a Server to Server configuration commented bellow that I use when migrating from host to host.

## Captain's log

- 2020-10-00 : migrated to yen on OpenBSD

## Configuration

```cfg
[Global]
    Name = yen.adyxax.org
    AdminInfo1 = Adyxax's IRC network
    AdminInfo2 = Hello to the geek reading that!
    AdminEMail = AAAAAA@adyxax.org
    HelpFile = /usr/local/share/doc/ngircd/Commands.txt
    Info = Adyxax's IRC server, the one that rocks
    MotdFile = /etc/ngircd/motd
    Network = adyxax.org
    Listen = ::,0.0.0.0
    Password = XXXXXX
    ServerUID = ngircd
    ServerGID = ngircd
[Limits]
    ConnectRetry = 60
    MaxConnections = 255
    MaxConnectionsIP = 15
    MaxJoins = 15
    MaxNickLength = 15
    MaxListSize = 100
    PingTimeout = 120
    PongTimeout = 20
[Options]
    AllowRemoteOper = no
    CloakHost = yen.adyxax.org
    DNS = yes
    OperCanUseMode = yes
    SyslogFacility = daemon
    PAM = no
[SSL]
    CertFile = /etc/ssl/irc.adyxax.org.crt
    DHFile = /etc/ngircd/dh4096.pem
    KeyFile = /etc/ssl/private/irc.adyxax.org.key
    Ports = 1337
[Operator]
    Name = adyxax
    Password = YYYYYY
    Mask = adyxax!~bbbbbb@*
#[Server]
#    Name = tale.adyxax.org
#    Host = tale.adyxax.org
#    Port = 1337
#    MyPassword = ZZZZZZ
#    PeerPassword = ZZZZZZ
#    Passive = no
#    SSLConnect = yes
[Channel]
    Name = #geek
    Topic = Thou Shall Respect™ in Here!
    Modes =
```
