---
title: "LDAP auth with nginx"
linkTitle: "LDAP auth with nginx"
date: 2018-03-05
description: >
  LDAP auth with nginx
---

{{< highlight sh >}}
ldap_server ldap {
    auth_ldap_cache_enabled on;
    auth_ldap_cache_expiration_time 10000;
    auth_ldap_cache_size 1000;

    url "ldaps://ldapslave.adyxax.org/ou=Users,dc=adyxax,dc=org?uid?sub?(objectClass=posixAccount)";
    binddn "cn=admin,dc=adyxax,dc=org";
    binddn_passwd secret;
    group_attribute memberUid;
    group_attribute_is_dn off;
    satisfy any;
    require valid_user;
    #require group "cn=admins,ou=groups,dc=adyxax,dc=org";
}
{{< /highlight >}}

