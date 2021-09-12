---
title: "Link to a deleted inode"
date: 2018-03-05
description: How to restore a hardlink to a deleted inode
tags:
- linux
- unix
---

## The problem

Sometimes a file gets deleted by mistake, but thankfully it is still opened by some software.

## The solution

Get the inode number from `lsof` (or from `fstat` if you are on a modern system), then run something like the following :

{{< highlight sh >}}
debugfs -w /dev/mapper/vg-home -R 'link <16008> /some/path'
{{< /highlight >}}

In this example 16008 is the inode number you want to link to (the < > are important, they tell debugfs you are manipulating an inode). Beware that **the path is relative to the root of the block device** you are restoring onto.
