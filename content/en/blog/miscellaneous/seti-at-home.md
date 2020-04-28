---
title: "Seti@Home"
linkTitle: "Seti@Home"
date: 2018-03-05
description: >
  Seti@Home
---

{{< highlight sh >}}
apt install boinc
echo "graou" > /var/lib/boinc-client/gui_rpc_auth.cfg
systemctl restart boinc-client
boinccmd --host localhost --passwd graou --get_messages 0
boinccmd --host localhost --passwd graou --get_state|less
boinccmd --host localhost --passwd graou --lookup_account http://setiathome.berkeley.edu <EMAIL> XXXXXX
boinccmd --host localhost --passwd graou --project_attach http://setiathome.berkeley.edu <ACCOUNT_KEY>
{{< /highlight >}}

