---
title: "About me"
description: Information about the author of this website
---

## Who am I?

Hello, and thanks for asking! My name is Julien Dessaux and Adyxax is my nickname. I am a {{< age >}} years old guy working in IT.

## Professional Career

### Head of IT at Intersec (2009-2016)

Intersec is a software company in the telecommunication sector.

I joined Intersec as a trainee in April 2009, then as the company's first full time system administrator in September 2009. At the time Intersec was a startup of just about 15 people. When I left in June 2016 it had grown up to more than 112 people with branch offices in three countries, and I am glad I was along for the ride.

Intersec gave me the opportunity of working as the head of IT for about 5 years (not counting the first year and a half when I was learning the ropes), participating in Intersec's growth by scaling the infrastructure and deploying lots of backbone services:
* Remote access with OpenVPN and IPsec tunnels.
* Emails with Postfix, Dovecot, Dspam, Postgrey, ClamAV and OpenLDAP.
* Backups with Bacula then Bareos.
* Monitoring with Nagios.
* Automating everything with Cfengine3 and bash and perl scripting.
* Issue tracking with Redmine, git hosting with gitolite3 and code review with gerrit.
* Linux (Debian and Centos/RedHat), virtualization with Ganeti, containerization with LXC.
* NFS and Samba file servers.
* OpenBSD firewalls and routers.
* Juniper and cisco switches, Juniper Wifi hardware with 802.1x security.

Besides this IT role, I also designed the high availability platforms we deployed Intersec's products on early on. It relied mostly on RedHat Cluster Suite and DRBD and I handled the training of developers and integrators on these technologies.

As a manager I also recruited and managed a small team of 2 people for a few years, 3 the last year.

I left Intersec in june 2016 after seven years, looking for new challenges and for a new life away from the capital. Paris is a great city, but I needed a change and left for Lyon.

### System and Network Architect at alter way (2016 - 2021)

alter way is a web hosting company.

I joined alter way in October 2016 for a purely technical role and a bit of a career shift towards networking and infrastructure. There I had the opportunity to rework many core systems and processes that helped the company grow in many ways.

On the networking side I helped put in production and operate our anti-ddos systems and reworked then maintained our bgp routers configurations for that purpose. I also lead the one year long upgrade project of our core network to 100G technologies based on Arista hardware. The core switches relied on OSPF as underlay and VxLAN as overlay. The routers also used OSPF as IGP.

I implemented a virtualized pre-production of all the core devices in gns3 in order to automate the configuration management and test protocol interactions. Automation was first implemented with ansible but was soon replaced with a perl tool for generating and deploying the configurations. Ansible was too slow and we went from a dozen minutes to redeploy the entire backbone configurations down to a few seconds.

I also maintained and improved the way we operate our netapp storage clusters by automating processes and standardizing configurations. This allowed to rework the way we operate our PRA to reduce downtimes and allow for proper testing of the PRA before we need it. I also handled the hardware refreshes and the storage migrations.

On the systems side I redesigned the backup platform from the ground up with a mix of bareos and docker on debian. The platform's usage was of about 120TB and managed to backup everything incrementaly every night on just two big storage servers.

On a final note I had the opportunity to work on the redesign of how we deploy and operate alter way's public cloud offering (networking, storage and compute). I worked on a mix of hardware virtualization and kubernetes and automated most things ansible and terraform. I also had my first experiences with cloud system administration while helping clients moving to hybrid architecture (a balanced mix of on premise and in the cloud).

It has been a great and diversified experience, but after five years I felt my future was not necessarily in an architect role with purely on premise hardware and decided to move on.

### Devops Engineering Manager at Lumapps (2021 - present)

TODO

## Education

I graduated with a master's degree in computer science from the [ISIMA](https://www.isima.fr/), an engineering school in France.

Prior to that I obtained with honours a Baccalaureate S option Mathematics (A-levels equivalent), then went on to study for competitive admission into French engineering colleges in Classes Préparatoires in Mathematics and Physics (MPSI/MP).

I am a French native speaker and consider myself fluent in English (I scored 920 at the TOEIC test). I have a pre-intermediate level in Spanish.

## Online presence

I have an activity pub account at [@adyxax@adyxax.org](https://fedi.adyxax.org/@adyxax) (a mastodon compatible self hosted instance). I also have a [Linkedin](https://www.linkedin.com/in/julien-dessaux-2124bb1b/) account that I do not use.

I maintain this website to showcase some of my works and interests. You can also look at my [personal git server](https://git.adyxax.org/adyxax) or my [github](https://github.com/adyxax) which mirrors most of my repositories. I can usually be found on oftc or libera IRC servers.

## Other interests

When I am not doing all the above, I like running, biking, hiking, skiing and reading.

## How to get in touch

You can write me an email at `julien -DOT- dessaux -AT- adyxax -DOT- org`, I will answer. If you want us to have some privacy, [here is my public gpg key](/static/F92E51B86E07177E.pgp). I will also respond on activity pub at `-AT- adyxax -AT- adyxax.org`.
