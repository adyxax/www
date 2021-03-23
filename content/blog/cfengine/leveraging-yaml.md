---
title: "Leveraging yaml with cfengine"
date: 2018-09-25
description: How to leverage yaml inventory files with cfengine
tags:
  - cfengine
---

## Introduction

CFEngine has core support for JSON and YAML. You can use this support to read, access, and merge JSON and YAML files and use these to keep policy files internal and simple. You
access the data using the usual cfengine standard primitives.

The use case bellow lacks a bit or error control with argument validation, it will fail miserably if the YAML file is invalid.

## Example yaml

In `cmdb/hosts/andromeda.yaml` we describe some properties of a host named andromeda:

{{< highlight yaml >}}
domain: adyxax.org
host_interface: dummy0
host_ip: "10.1.0.255"

tunnels:
    collab:
        port: 1195
        ip: "10.1.0.15"
        peer: "10.1.0.14"
        remote_host: collab.example.net
        remote_port: 1199
    legend:
        port: 1194
        ip: "10.1.0.3"
        peer: "10.1.0.2"
        remote_host: legend.adyxax.org
        remote_port: 1195
{{< /highlight >}}

## Reading the yaml

I am bundling the values in a common bundle, accessible globally. This is one of the first bundles processed in the order my policy files are loaded. This is just an extract, you can load multiple files and merge them to distribute common
settings :
{{< highlight yaml >}}
bundle common g
{
    vars:
        has_host_data::
            "host_data" data => readyaml("$(sys.inputdir)/cmdb/hosts/$(sys.host).yaml", 100k);
    classes:
        any::
            "has_host_data" expression => fileexists("$(sys.inputdir)/cmdb/hosts/$(sys.host).yaml");
}
{{< /highlight >}}

## Using the data

### Cfengine agent bundle

We access the data using the global g.host_data variable, here is a complete example :
{{< highlight yaml >}}
bundle agent openvpn
{
    vars:
        any::
            "tunnels" slist => getindices("g.host_data[tunnels]");
    files:
        any::
            "/etc/openvpn/common.key"
                create => "true",
                edit_defaults => empty,
                perms => system_owned("440"),
                copy_from => local_dcp("$(sys.inputdir)/templates/openvpn/common.key.cftpl"),
                classes => if_repaired("openvpn_common_key_repaired");
    methods:
        any::
            "any" usebundle => install_package("$(this.bundle)", "openvpn");
            "any" usebundle => openvpn_tunnel("$(tunnels)");
    services:
        linux::
            "openvpn@$(tunnels)"
                service_policy => "start",
                classes => if_repaired("tunnel_$(tunnels)_service_repaired");
    commands:
        any::
            "/usr/sbin/service openvpn@$(tunnels) restart"
                classes => if_repaired("tunnel_$(tunnels)_service_repaired"),
                ifvarclass => "openvpn_common_key_repaired";
    reports:
        any::
            "$(this.bundle): common.key repaired" ifvarclass => "openvpn_common_key_repaired";
            "$(this.bundle): $(tunnels) service repaired" ifvarclass => "tunnel_$(tunnels)_service_repaired";
}
 
bundle agent openvpn_tunnel(tunnel)
{
    classes:
        any::
            "has_remote" and => { isvariable("g.host_data[tunnels][$(tunnel)][remote_host]"),
                                  isvariable("g.host_data[tunnels][$(tunnel)][remote_port]") };
    files:
        any::
            "/etc/openvpn/$(tunnel).conf"
                create => "true",
                edit_defaults => empty,
                perms => system_owned("440"),
                edit_template => "$(sys.inputdir)/templates/openvpn/tunnel.conf.cftpl",
                template_method => "cfengine",
                classes => if_repaired("openvpn_$(tunnel)_conf_repaired");
    commands:
        any::
            "/usr/sbin/service openvpn@$(tunnel) restart"
                classes => if_repaired("tunnel_$(tunnel)_service_repaired"),
                ifvarclass => "openvpn_$(tunnel)_conf_repaired";
    reports:
        any::
            "$(this.bundle): $(tunnel).conf repaired" ifvarclass => "openvpn_$(tunnel)_conf_repaired";
            "$(this.bundle): $(tunnel) service repaired" ifvarclass => "tunnel_$(tunnel)_service_repaired";
}
{{< /highlight >}}

### Template file

Templates can reference the g.host_data too, like in the following :
{{< highlight cfg >}}
[%CFEngine BEGIN %]
proto udp
port $(g.host_data[tunnels][$(openvpn_tunnel.tunnel)][port])
dev-type tun
dev tun_$(openvpn_tunnel.tunnel)
comp-lzo
script-security 2

ping 10
ping-restart 20
ping-timer-rem
persist-tun
persist-key

cipher AES-128-CBC

secret /etc/openvpn/common.key
ifconfig $(g.host_data[tunnels][$(openvpn_tunnel.tunnel)][ip]) $(g.host_data[tunnels][$(openvpn_tunnel.tunnel)][peer])

user nobody
[%CFEngine centos:: %]
group nobody
[%CFEngine ubuntu:: %]
group nogroup

[%CFEngine has_remote:: %]
remote $(g.host_data[tunnels][$(openvpn_tunnel.tunnel)][remote_host]) $(g.host_data[tunnels][$(openvpn_tunnel.tunnel)][remote_port])

[%CFEngine END %]
{{< /highlight >}}

## References
- https://docs.cfengine.com/docs/master/examples-tutorials-json-yaml-support-in-cfengine.html
- https://docs.cfengine.com/docs/3.10/reference-functions-readyaml.html
- https://docs.cfengine.com/docs/3.10/reference-functions-mergedata.html
