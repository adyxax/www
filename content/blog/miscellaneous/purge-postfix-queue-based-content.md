---
title: "Purge postfix queue based on email contents"
linkTitle: "Purge postfix queue based on email contents"
date: 2009-04-27
description: >
  Purge postfix queue based on email contents
---


{{< highlight sh >}}
find /var/spool/postfix/deferred/ -type f -exec grep -li 'XXX' '{}' \; | xargs -n1 basename | xargs -n1 postsuper -d
{{< /highlight >}}

