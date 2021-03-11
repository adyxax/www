---
title: "Qmail"
linkTitle: "Qmail"
date: 2018-03-05
description: >
  Qmail
---

## Commands

- Get statistics : `qmail-qstat`
- list queued mails : `qmail-qread`
- Read an email in the queue (NNNN is the #id from qmail-qread) : `find /var/qmail/queue -name NNNN| xargs cat | less`
- Change queue lifetime for qmail in seconds (example here for 15 days) : `echo 1296000 > /var/qmail/control/queuelifetime`

## References

- http://www.lifewithqmail.org/lwq.html
- http://www.fileformat.info/tip/linux/qmailnow.htm
- https://www.hivelocity.net/kb/how-to-change-queue-lifetime-for-qmail/

