---
title: "adyxax.org"
description: a set of pages about the computer infrastructure powering this website and other services
---

## What is adyxax.org?

adyxax.org is very much like a small personnal cloud of inexpensive servers hosted here and there. I am using my experience as a professional
sysadmin to make it all work and provide various services that are useful to me and people that are close to me. As a good sysadmin, I am trying to be lazy and build the most self
maintainable solution, with as little maintenance overhead as possible.

It used to rely on mostly [Gentoo]({{< ref "/tags/Gentoo" >}}) (and some optional [OpenBSD]({{< ref "/tags/OpenBSD" >}})) servers interconnected with point to point openvpn links. Services ran inside lxd on alpine linux containers. Communications between all those services work
thanks to dynamic routing with bird and ospf along those openvpn links. I made extensive use of ansible to orchestrate all that, deploy the containers and manage them.

Even though it worked really well for years, I do not plan to blog a lot about this setup unless someone interested writes me to request information about it. On this new documentation site I plan to focus on how I am migrating the most stable and boring parts on OpenBSD hosts (so without containerisation). The less important or more changing services will be migrated on [kubernetes]({{< ref "kubernetes" >}}) as a learning experience. Even though my custom setup with lxd on gentoo has always worked well it still was a rather unusual design that sometimes required maintenance following updates. Even if I am proud of its stability and reliability... It is not good for me to not look deeper into new technologies. Gentoo, OpenBSD and LXD is not the most popular combination out there. I will not abandon it completely (I do not imagine my laptop running anything other than gentoo), but working on more employable skills will do me good.

## Why write about it?

As a system and network administrator I believe I have a deep understanding of linux and other unix like operating systems, networking and storage, and even with all that knowledge and experience getting on kubernetes is hard. Deploying kubernetes itself is not hard, but there are so so many choices that you make each steps of the way that will define how maintainable and debuggable it will be. Choosing what kubernetes flavor to deploy is one tough choice, choosing how to deploy it is another. Then choosing your network then storage providers are a juicy ones too, so many subtle differences come into play!

On a personal note I also believe there are way too many blogs that focus on the hello world aspects and quick and dirty deployments that show up in google results, I will try to change that a bit. Writing about the choices I made will also help me reflect on them as this infrastructure evolves and grows.

## Services

