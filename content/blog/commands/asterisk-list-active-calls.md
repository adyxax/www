---
title: "How to have asterisk call you into a meeting"
date: 2018-09-25
description: How to have asterisk call you itself into a meeting
tags:
  - asterisk
---

## Using the cli

At alterway we sometimes have DTMF problems that prevent my mobile from joining a conference room. Here is something I use to have asterisk call me
and place me inside the room :

```
channel originate SIP/numlog/06XXXXXXXX application MeetMe 85224,M,secret
```
