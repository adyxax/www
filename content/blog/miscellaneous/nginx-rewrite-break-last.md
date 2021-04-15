---
title: "Break vs Last in nginx rewrites"
date: 2021-04-15
description: These two statements differ slightly
tags:
  - nginx
---

## Introduction

Today I was called in escalation to debug why a set of rewrites was suddenly misbehaving in one of my employers' clients configurations. The origin of the confusion is that both keywords are synonyms when rewrite rules are used outside of a location block, but not when used inside such block!

## Outside a location block

When used outside a location block, these keywords stop the rules evaluation and then evaluate to a location. Consider the following example :
{{< highlight conf >}}
server {
	[...]
	location / {
		return 200 'root';
	}
	location /texts/ {
		return 200 'texts';
	}
	location /configs/ {
		return 200 'configs';
	}
	rewrite ([^/]+\.txt)$ /texts/$1 last;
	rewrite ([^/]+\.cfg)$ /configs/$1 break;
}
{{< /highlight >}}

If you run several curls you can see the behaviour illustrated :

{{< highlight sh >}}
curl http://localhost/test
root   # we hit the root handler without any redirect matching

curl http://localhost/test.txt
texts  # we hit the rewrite to /texts/test.txt, which is then reevaluated and hits the texts location

curl http://localhost/test.cfg
configs  # we hit the rewrite to /configs/test.cfg, which is then reevaluated and hits the configs location
{{< /highlight >}}

## Inside a location block

When used inside a location block a rewrite rule flagged last will eventually trigger a location change (it is reevaluated based on the new url) but this does not happen when break is used.

Consider the following example :
{{< highlight conf >}}
server {
	[...]
	location / {
		return 200 'root';
		rewrite ([^/]+\.txt)$ /texts/$1 last;
		rewrite ([^/]+\.cfg)$ /configs/$1 break;
	}
	location /texts/ {
		return 200 'texts';
	}
	location /configs/ {
		return 200 'configs';
	}
}
{{< /highlight >}}

If you run several curls you can see the behaviour illustrated :

{{< highlight sh >}}
curl http://localhost/test
root   # we hit the root handler without any redirect matching

curl http://localhost/test.txt
texts  # we hit the rewrite to /texts/test.txt, which is then reevaluated and hits the texts location

curl http://localhost/test.cfg
404 NOT FOUND     # or maybe a file if you had a test.cfg file in your root directory!
{{< /highlight >}}

Can you see what happened for the last test? The break statement in a location stops all evaluation, and do not reevaluate the resulting path in any location. Nginx therefore tries to serve a file from the root directory specified for the server. That is the reason we do not get either `root` or `configs` as outputs.

## Mixing both

If you mix up both sets of rewrite rules and they overlap, the ones outside any location will be evaluated first.
