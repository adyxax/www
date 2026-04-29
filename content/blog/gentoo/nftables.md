---
title: "My current nftables laptop configuration"
date: 2026-04-29
description: "I wish pf existed on Linux!"
tags:
  - nftables
---

## Introduction

I have blogged about my pf firewall configurations a few times, but never my
Linux ones. There is nothing especially unusual about it, but it does differ
somewhat from the common nftables examples.

## Configuration

This is the configuration for my Gentoo laptop. It has two Wireguard interfaces
and references two egress interfaces, one for Ethernet and one for WiFi:

``` cfg
#!/sbin/nft -f

flush ruleset

define allowed_icmp_types = { echo-reply, echo-request };
define trusted_icmp_types = { destination-unreachable, time-exceeded };
define allowed_icmpv6_types = { nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, echo-request, echo-reply };

define egress_ifs = { enp0s31f6, wlp0s20f3 };

table inet filter {
  set private4 {
    type ipv4_addr;
    flags constant, interval;
    elements = { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 };
  }
  set private6 {
    type ipv6_addr;
    flags constant, interval;
    elements = { fd00::/8, fe80::/10 };
  }
  chain forward_docker {
    # forward docker traffic only to the Internet, not to wireguard, our LAN or
    # other interfaces
    oifname $egress_ifs ip saddr @private4 ip daddr != @private4 counter accept;
    oifname $egress_ifs ip6 saddr @private6 ip6 daddr != fd00::/8 counter accept;
  }
  chain input_docker {
    # Allow container access to local Postgres and Valkey
    ct state new tcp dport { 5432, 6379 } counter accept;
  }
  chain input_egress {
    ct state new tcp dport ssh limit rate 5/minute counter accept;
  }
  chain input_wireguard_adyxax {
    icmp type $trusted_icmp_types counter accept;
    ip protocol ospf counter accept;
    ip6 nexthdr ospf counter accept;
    udp dport { 3784, 4784 } accept; # Allow BFD
    ct state new tcp dport ssh counter accept;
  }
  chain input_wireguard_normal {
    icmp type $trusted_icmp_types counter accept;
    ct state new tcp dport ssh limit rate 5/minute counter accept;
  }
  # Chain hooks
  chain input {
    type filter hook input priority 0;
    policy drop;
    iifname lo accept;
    ct state {established, related} counter accept;
    ct state invalid counter drop;
    icmp type $allowed_icmp_types counter accept;
    icmpv6 type $allowed_icmpv6_types counter accept;
    iifname docker0 counter jump input_docker;
    iifname $egress_ifs counter jump input_egress;
    iifname wg-myth counter jump input_wireguard_adyxax;
    iifname wg-normal counter jump input_wireguard_normal;
    # drop mDNS traffic without logging
    ip daddr 224.0.0.251 udp dport 5353 counter drop;
    # drop multicast membership traffic without logging
    ip protocol igmp counter drop;
    log prefix "input drop: " limit rate 10/second counter drop;
    counter drop;
  }
  chain forward {
    type filter hook forward priority 0;
    policy drop;
    ct state {established, related} counter accept;
    ct state invalid counter drop;
    iifname docker0 counter jump forward_docker;
    log prefix "forward drop: " limit rate 10/second counter drop;
    counter drop;
  }
  chain output {
    type filter hook output priority 0;
    policy accept;
    ct state {established, related} counter accept;
    ct state invalid counter drop;
    ct state new counter accept;
    ip protocol icmp counter accept;
    ip6 nexthdr icmpv6 counter accept;
    meta l4proto ipv6-icmp counter accept;
    log prefix "output accept: " counter accept;
  }
}

table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat;
    policy accept;
    # Only NAT traffic to the Internet, not to our LAN
    oifname $egress_ifs \
            ip daddr != 10.0.0.0/8 \
            ip daddr != 172.16.0.0/12 \
            ip daddr != 192.168.0.0/16 \
            counter masquerade;
  }
}

table netdev filter {
  chain ingress {
    type filter hook ingress device $egress_ifs priority -500;
    # Drop all fragments.
    ip frag-off & 0x1fff != 0 counter drop
    # Drop XMAS packets.
    tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|psh|ack|urg counter drop
    # Drop NULL packets.
    tcp flags & (fin|syn|rst|psh|ack|urg) == 0x0 counter drop
    # Drop uncommon MSS values.
    tcp flags syn tcp option maxseg size 1-535 counter drop
  }
}
```

I like the private IPv4 and IPv6 sets (taken from my pf configurations), though
they are not as convenient to use in nftables as they are in pf. Nftables does
not let sets express inverted matches like pf does, which limits how compactly
some rules can be written. They are also scoped to a single table rather than being globally reusable.

I do not allow Docker to modify my firewall ruleset, I want it to remain all
static and predictable. That is why the Docker related rules are written
explicitly here.

## Conclusion

Overall, this setup is fairly conservative: default drop on input and forward
while explicit handling of traffic on each interface for egress, containers and
wireguard.

If you have nftables tips, I would be glad to read them. Feel free to reach me
by email or on Mastodon.
