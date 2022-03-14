---
title: Fixing a redis chart
date: 2022-03-14
description: I contributed a preStop script to trigger a failover before a redis master is terminated
tags:
  - helm
  - kubernetes
  - redis
---

## Introduction

Back in January I contributed a fix to a redis chart : https://github.com/DandyDeveloper/charts/pull/178. I should have blogged about it at the time, but life happened and I did not.

## The problem

This charts deploys a redis cluster and I noticed that when a redis master gets terminated there is a downtime before a new one gets elected.

One of the challenges in fixing this behaviour was to do it in a way that would get accepted upstream. That meant respecting the style in place to manage the chart : scripts are deployed in the images as configmap values and are written inside a helm template... yummy! This allows to use helm variables easily, and avoids maintaining custom images but made linting or shellcheck validation a pain to do.

## The solution

This restart behaviour can be fixed with a preStop script that checks if the terminating pod is a redis master. If that is the case, we trigger a failover before shutting then wait for it to complete. My fix was accepted and merged upstream, I am proud I had the opportunity to contribute back to this chart in the community spirit of open source software.
