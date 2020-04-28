---
title: "Some bacula/bareos commands"
linkTitle: "Some bacula/bareos commands"
date: 2018-01-10
description: >
  Some bacula/bareos commands
---

Bacula is a backup software, bareos is a fork of it. Here are some tips and solutions to specific problems.

## Adjust an existing volume for pool configuration changes

In bconsole, run the following commands and follow the prompts :
{{< highlight sh >}}
update pool from resource
update all volumes in pool
{{< /highlight >}}

## Using bextract

On the sd you need to have a valid device name with the path to your tape, then run :
{{< highlight sh >}}
bextract -V <volume names separated by |> <device-name>
<directory-to-store-files>
{{< /highlight >}}

## Integer out of range sql error

If you get an sql error `integer out of range` for an insert query in the catalog, check the id sequence for the table which had the error. For
example with the basefiles table :
{{< highlight sql >}}
select nextval('basefiles_baseid_seq');
{{< /highlight >}}

You can then fix it with :
{{< highlight sql >}}
alter table BaseFiles alter column baseid set data type bigint;
{{< /highlight >}}
