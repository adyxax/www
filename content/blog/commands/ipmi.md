---
title: "ipmitool"
date: 2018-03-05
description: some ipmitool command examples
tags:
  - simple utilities
---

## Usage examples
- launch ipmi shell : `ipmitool -H XX.XX.XX.XX -C3 -I lanplus -U <ipmi_user> shell`
- launch ipmi remote text console : `ipmitool -H XX.XX.XX.XX -C3 -I lanplus -U <ipmi_user> sol activate`
- Show local ipmi lan configuration : `ipmitool lan print`
- Update local ipmi lan configuration :
{{< highlight sh >}}
ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr 10.31.149.39
ipmitool lan set 1 netmask 255.255.255.0
mc reset cold
{{< /highlight >}}
