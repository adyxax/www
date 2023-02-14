---
title: A series of articles about wireguard
description: A fast, modern and secure vpn tunnel
date: 2023-02-14
tags:
- vpn
- wireguard
---

## Intoduction

I have been using [a fast, modern and secure vpn technology named wireguard](https://www.wireguard.com/) on every corner of my personal infrastructure for several years now and realized I never bloged about it before my [factorio freebsd jail article]({{< ref "factorio-to-nas.md" >}})! Therefore I am starting a series of articles about wireguard, its configuration on the various operating systems I use daily, and even on kubernetes.

## My history with VPNs

Before wireguard, I built and managed my own overlay network using a combination of point to point [OpenVPN tunnels](https://openvpn.net/source-code/) (damn this site is ugly and has aged badly!) and [the bird routing daemon](https://www.wireguard.com/).

My servers all had at least two connections to others and all clients too. Bird ran the OSPF protocol over the openvpn interfaces and announced the routes to the over servers. This allowed dynamic reconfiguration and some fun times with asymetric routing. I also had bird listen on my home network lan interfaces for some clever traffic optimisations.

At the time I made heavy use of linux container with LXC, and could expose them through OSPF too. Such an elegant use for dynamic routing!

For some time I also had a mix of BGP (on the backbone servers) and OSPF (for client or container links) of this overlay running, mainly to use BGP more for my personal experience, but all in all it was less reliable than plain old OSPF and more of a pain to setup.

## Wireguard, on the rocks

At some point I heard about wireguard's performance and simplicity and decided to give it a try. It was nice but had drawbacks until the project gained enough traction to be implemented natively by the kernels of the multiple operating systems I manage.

The performance and ease of setup is great, but I lost the overlay convenience I had with OSPF on top of OpenVPN. Indeed one of the strength and limitation of wireguard is that your routing is tied to the trafic you allow a peer to send you. It is functional, but does not leave much room for fun stuff.

## OpenVPN is not dead

I still have OpenVPN in one place though: listenning on TCP port 443, TCP port 53 and UDP port 53. This allows me to securely escape most networks that block wireguard.

If you are interested in my older OpenVPN + OSPF setup please let me know by email or on mastodon and I will write about it, otherwise I will simply focus on my current setup using wireguard.
