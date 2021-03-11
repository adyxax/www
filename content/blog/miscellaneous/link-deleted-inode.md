---
title: "Link to a deleted inode"
linkTitle: "Link to a deleted inode"
date: 2018-03-05
description: >
  Link to a deleted inode
---

Get the inode number from `lsof`, then run `debugfs -w /dev/mapper/vg-home -R 'link <16008> /some/path'` where 16008 is the inode number (the < > are important, they tell debugfs you manipulate an inode). The path is relative to the root of the block device you are restoring onto.

