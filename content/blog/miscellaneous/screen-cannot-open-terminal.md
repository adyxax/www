---
title: "Screen cannot open terminal error"
linkTitle: "Screen cannot open terminal error"
date: 2018-07-03
description: >
  Screen cannot open terminal error
---

If you encounter :
{{< highlight sh >}}
Cannot open your terminal '/dev/pts/0' - please check.
{{< /highlight >}}

Then you did not open the shell with the user you logged in with. You can make screen happy by running : 
{{< highlight sh >}}
script /dev/null
{{< /highlight >}}
