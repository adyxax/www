---
title: Testing eventline
description: An open source platform to manage all your scripts and schedule jobs
date: 2022-09-03
tags:
- toolbox
---

## Introduction

For the last few weeks I have been using more and more [eventline](https://www.exograd.com/products/eventline/), an open source platform to manage my scripts and schedule jobs that run those scripts when something happens.

## My use case for eventline

After 13 years as a sysadmin I have accumulated a lot of experiencing scripting and glueing things together. Before eventline I was deploying said scripts first with cfengine3 and more recently with ansible. These were of course versioned with git and lived in custom ansible roles that needed them. Some other more complex scripts lived in my gitolite-admin repository and were deployed as git hooks, forming a barebones ci/cd. I was content with this because I did not know of an open source solution to do better and I did not imagined there could be.

With eventline I have been able to bring all these scripts in a single place and create what eventline calls jobs from them. My git hooks became calls to evcli, the cli tool that interacts with eventline. There is a webui, but I find myself using mostly the cli.

This move simplified my scripts and processes:
- eventline now takes care of logging the scripts outputs, successes and failures
- I de-duplicated a lot of code by using job steps that run smaller scripts taking different arguments
- I no longer need complicated logic for locking and preventing concurrent executions in critical sections of deployment scripts
- secrets the jobs need are now safely stored in eventline instead of on the servers and my ansible repository
- I no longer need to worry about cleaning the target machines when I change or stop using a script

## The state of eventline

I have been very happy with eventline. The [documentation](https://www.exograd.com/doc/eventline/handbook.html) is exhaustive and easy to navigate. All in all it is a very KISS solution and an hour is all I needed to grasp the concepts. Still it is very flexible and offers many possibilities in composing jobs.

I like that the daemon is lightweight using only 16M of resident memory right now. The only dependency is a postgresql database to connect to, but it needs to be version 14 or higher so quite recent. The pgcrypto extension must be installed, I presume in order to store the secrets. The fact that it does not use any other kind of storage makes it easy to install, monitor and backup. There is a metrics exporter builtin but I did not test it yet.

I am glad that FreeBSD is supported as a first class citizen with a package repository and I deployed it this way. There is also an ubuntu repository as well as the linux container image expected today.

The one thing I wish was implemented is api keys with scopes that limit what job an host running evcli can schedule, but it is on the roadmap for a future release. Eventline is not quite 1.0 yet but it has been very stable and I did not experience a single crash in six or seven weeks of increasing usage.

## Conclusion

I would have never suspected I needed something to manage my scripts before, but after a few weeks I can say that it would be painful to live without eventline.

I am now cleaning up my scripts repository and will detail my eventline jobs implementation in a next article.
