---
title: "Use spaces in fstab"
date: 2011-09-29
description: How to use spaces in a folder name in fstab
tags:
  - unix
---

## The problem

Spaces are used to separate fields in the fstab, if you have spaces in the path of a mount point we cannot type them directly.

## The solution

Here is how to use spaces in a folder name in fstab : you put `\040` where you want a space.
