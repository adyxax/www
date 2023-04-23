---
title: smtpd.conf
description: OpenSMTPD templates
tags:
- OpenBSD
---

## Simple relay

Here is my template for a simple smtp relay. The host names in the outbound action are to be customized obviously, and in my setups `yen` the relay destination is only reachable via wireguard. If not in such setup, smtps with authentication is to be configured :

```cfg
table aliases file:/etc/mail/aliases

listen on socket
listen on lo0

action "local_mail" mbox alias <aliases>
action "outbound" relay host "smtp://yen" mail-from "root+phoenix@adyxax.org"

match from local for local action "local_mail"
match from local for any action "outbound"
```

## Primary mx

Here is my primary mx configuration as a sample :

```cfg
pki adyxax.org cert "/etc/ssl/yen.adyxax.org.crt"
pki adyxax.org key  "/etc/ssl/private/yen.adyxax.org.key"


filter "dkimsign"   proc-exec "filter-dkimsign -d adyxax.eu -d adyxax.org -s 2020111301 -k /etc/mail/dkim/private.key" user _dkimsign group _dkimsign
filter check_dyndns phase connect match rdns     regex { '.*\.dyn\..*', '.*\.dsl\..*' }  disconnect "550 no residential connections"
filter check_rdns   phase connect match !rdns    disconnect "550 no rDNS is so 80s"
filter check_fcrdns phase connect match !fcrdns  disconnect "550 no FCrDNS is so 80s"


table aliases  file:/etc/mail/aliases
table domains  file:/etc/mail/domains
table virtuals file:/etc/mail/virtuals


listen on egress tls   pki adyxax.org  filter { check_dyndns, check_rdns, check_fcrdns }
listen on egress port  submission tls-require pki adyxax.org auth filter dkimsign
listen on socket
listen on lo0
listen on wg0 filter dkimsign  # if you need to relay emails from your wireguard to the internet like I do


action "local_mail" mbox alias <aliases>
action "cyrus"      lmtp "/var/run/cyrus/socket/lmtp" virtual <virtuals>
action "outbound"   relay


match  from any     for domain <domains> action "cyrus"
match  from local   for local action "local_mail"

match from any   auth  for any action "outbound"
match from mail-from "root+phoenix@adyxax.org" for any action "outbound"  # if you need to relay emails from another machine to the internet like I do
```

## Secondary mx

Here is my secondary mx configuration as a sample :
```conf
pki adyxax.org cert "/etc/ssl/myth.adyxax.org.crt"
pki adyxax.org key  "/etc/ssl/private/myth.adyxax.org.key"


filter "dkimsign"   proc-exec "filter-dkimsign -d adyxax.eu -d adyxax.org -s 2020111301 -k /etc/mail/dkim/private.key" user _dkimsign group _dkimsign
filter check_dyndns phase connect match rdns     regex { '.*\.dyn\..*', '.*\.dsl\..*' }  disconnect "550 no residential connections"
filter check_rdns   phase connect match !rdns    disconnect "550 no rDNS is so 80s"
filter check_fcrdns phase connect match !fcrdns  disconnect "550 no FCrDNS is so 80s"


table aliases  file:/etc/mail/aliases
table domains  file:/etc/mail/domains


listen on egress tls   pki adyxax.org  filter { check_dyndns, check_rdns, check_fcrdns }
listen on socket filter dkimsign
listen on lo0 filter dkimsign


action "local_mail" mbox alias <aliases>
action "relay_to_yen" relay backup tls


match  from any     for domain <domains> action "relay_to_yen"
match  from local   for local action "local_mail"
```
