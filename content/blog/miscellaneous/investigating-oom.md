---
title: How to list oom killer score of running linux processus
description: a shell command that could be a one liner
date: 2021-10-05
tags:
- linux
- toolbox
---

## Introduction

There seems to be a missing piece for investigating what the oom killer will do when a linux kernel will run out of memory. Since oom_scores can be adjusted, looking at memory consumption is not enough to get a clear picture.

## The command

The base of the command came from a colleague, I refined it with the sort and tail :
```sh
while read -r pid comm; do
	printf '%d\t%d\t%s\n' "$pid" "$(cat /proc/$pid/oom_score)" "$comm"
done < <(ps -e -o pid= -o comm=)|sort -n -k2|tail
```

On a busy server, the output will look like :
```
306	2	systemd-journal
673	2	haproxy
616	6	puppet
8370	7	mcollectived
1728	8	varnishncsa
14652	9	php-fpm7.2
14668	10	php-fpm7.2
14653	13	php-fpm7.2
1415	186	cache-main
29124	313	mysqld
```
