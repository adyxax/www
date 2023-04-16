---
title: How to properly backup your SQLite databases
description: I used to simply .dump those
date: 2021-11-09
tags:
- backups
- SQLite
---

## Introduction

SQLite is great and I have been using it for years while self-hosting various services. It is easier, lighter and fast enough for most needs which is critical when the time you can spend managing your personal infrastructure is finite.

Recently while talking with a developer friend I learned about the `user_version` PRAGMA, which could be a simple way to handle migrations in a custom app. For migrations to work you need a way to save the current revision of your schema somewhere : I was using a table for that, with a single column and a single row to store that revision. This PRAGMA would be a nice way to handle this in SQLite.

## The backup problem

The problem with this PRAGMA is that it does not appear in a `.dump`! So if you rely on this to backup your databases (like I did) then you would lose the schema revision upon restoring your service, or migrating it to another host.

When looking into this problem I learned that a better way to handle SQLite backups is with `VACUUM INTO 'file.db';` (added in SQLite 3.27 in early 2019). Not only does this create a perfect copy of your database at the point in time you run this command, the PRAGMA are kept and the indexes will not need to be rebuilt!

## Conclusion

I switched all my SQLite backups to `VACUUM INTO` and will not look back!

If by chance you are using my [borg ansible role]({{< ref "docs/adyxax.org/backups/borg-ansible-role.md" >}}) to manage your backups, here is what an SQLite job entry looks like :
```
- name: srv-short-db
  path: "/tmp/short.db"
  pre_command: "echo \"VACUUM INTO '/tmp/short.db'\"|sqlite3 /srv/short-data/short.db"
  post_command: "rm -f /tmp/short.db"
```

I did not yet migrate away from my schema version table to replace it with the pragma : I need to think about it more before committing to this kind of change.
