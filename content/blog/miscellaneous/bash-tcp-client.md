---
title: "Bash tcp client"
date: 2018-03-21
description: Bash tcp client
tags:
  - toolbox
---

## Having some fun with bash

There are some fun toys in bash. I would not rely on it for a production script, but here is one such things :

```sh
exec 5<>/dev/tcp/10.1.0.254/8080
bash$ echo -e "GET / HTTP/1.0\n" >&5
bash$ cat <&5
```
