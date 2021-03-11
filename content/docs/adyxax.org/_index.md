---
title: "adyxax.org"
description: a set of pages about the computer infrastructure powering this website and other services
---

## What is adyxax.org?

adyxax.org is very much like a small personnal cloud of inexpensive servers hosted here and there. I am using my experience as a
sysadmin to make it all work and provide various services that are useful to me and people that are close to me. As a good sysadmin, I am trying to be lazy and build the most self
maintainable solution, with as little maintenance overhead as possible.

It used to rely on mostly gentoo (and some optional openbsd) servers interconnected with point to point openvpn links. Services ran inside lxd on alpine linux containers. Communications between all those services work
thanks to dynamic routing with bird and ospf along those openvpn links. I made extensive use of ansible to orchestrate all that, deploy the containers and manage them.

Even though it worked really well for years, I do not plan to blog a lot about this setup... but that can change if someone interested writes me at julien -DOT- dessaux -AT- adyxax -DOT- org. On this new documentation site I plan to focus on how I am migrating some of it on kubernetes, because even if it has always worked well it still is a rather unusual infrastructure. Even if I am proud of it, it is stable and easy and comfortable... It is not good for me to not look deeper into new technologies. Gentoo, OpenBSD and LXD is not the most popular combination out there. I will not abandon it completely, but working on more employable skills will do me good.

## Why write about it?

As a system and network administrator I believe I have a deep understanding of linux and other unix like operating systems, networking and storage, and even with all that knowledge and experience getting on kubernetes is hard. Deploying kubernetes itself is not hard, but there are so so many choices that you make each steps of the way that will define how hard it is going to be to maintain and debug. Choosing what kubernetes flavor to deploy is one tough choice, choosing how to deploy it is another. Then choosing your network provider is a juicy one, so many subtle differences come into play!

I believe there are way too many blogs that focus on the hello world aspects and quick and dirty deployments... and those come out way too often in google search results. Writing about the choices I made will also help me reflect on them as this infrastructure evolves and grows.

