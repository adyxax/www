---
title: "Seti@Home"
date: 2018-03-05
description: Getting back into Seti@Home 15 years later
tags:
  - linux
  - toolbox
---

## Introduction

Me and some friends were feeling nostalgics of running Seti@Home as a screensaver in the early 2000s and were delighted to see that the project is still alive and kicking.

## The commands

{{< highlight sh >}}
apt install boinc
echo "graou" > /var/lib/boinc-client/gui_rpc_auth.cfg
systemctl restart boinc-client
boinccmd --host localhost --passwd graou --get_messages 0
boinccmd --host localhost --passwd graou --get_state|less
boinccmd --host localhost --passwd graou --lookup_account http://setiathome.berkeley.edu <EMAIL> XXXXXX
boinccmd --host localhost --passwd graou --project_attach http://setiathome.berkeley.edu <ACCOUNT_KEY>
{{< /highlight >}}
