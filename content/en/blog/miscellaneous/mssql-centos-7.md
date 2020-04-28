---
title: "Installing mssql on centos 7"
linkTitle: "Installing mssql on centos 7"
date: 2019-07-09
description: >
  Installing mssql on centos 7
---

{{< highlight sh >}}
vi /etc/sysconfig/network-scripts/ifcfg-eth0
vi /etc/resolv.conf
curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo
curl -o /etc/yum.repos.d/mssql-prod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
yum update
yum install -y mssql-server mssql-tools
yum install -y sudo
localectl set-locale LANG=en_US.utf8
echo "export LANG=en_US.UTF-8" >> /etc/profile.d/locale.sh
echo "export LANGUAGE=en_US.UTF-8" >> /etc/profile.d/locale.sh
yum install -y openssh-server
systemctl enable sshd
systemctl start sshd
passwd
/opt/mssql/bin/mssql-conf setup
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -p
{{< /highlight >}}

