---
title: "Some nmap common usages"
date: 2020-03-19
description: nmap command examples
tags:
  - toolbox
---

## Introduction

Too often I have to go through the man page to remember the flags I need, so here is a little summary.

## The commands

- Initiate a detailed host scan : ''nmap -v -sV -O serveraddr''
- Initiate a ping scan without port scan : ''nmap -sn 10.1.0.0/24''
- The same ping scan with greppable output : ''nmap -sn -oG - 10.0.33.0/24''
