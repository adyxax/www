---
title: Getting started with Oracle Cloud Infrastructure
description: Oracle Cloud Infrastructure's always free tier is very generous
date: 2021-09-05
tags:
  - terraform
---

## Introduction

Oracle Cloud Infrastructure provides quite a generous always free tier for you to use and test their cloud... or host some light services. But getting started was a little difficult with many pieces missing or incomplete in the examples, especially how to configure ipv6 on your instances.

The documentation is very good and exhaustive but information was scattered : the following should help you get started right after you create your oracle cloud infrastructure's account.

## Create your API access

In order to terraform your infrastructure, you are going to need to generate an api access which is composed of a key and several other things :
- Open the web console, click the top left menu and select `Identity & Security` then `Users`.
- Click your account
- Scroll to bottom left and select `API Keys`
- click `Add an api key`
- Select `Generic API Key Pair`, download the private key file then click `Add`
- Copy the information displayed for the next phase

## Terraform

### Provider configuration

Here is the relevant snippet from my `providers.tf` file :
```hcl
variable "oracle_tenancy_ocid" {}
variable "oracle_user_ocid" {}
variable "oracle_fingerprint" {}
provider "oci" {
  tenancy_ocid     = var.oracle_tenancy_ocid
  user_ocid        = var.oracle_user_ocid
  fingerprint      = var.oracle_fingerprint
  private_key_path = "../tf-common/oracle_key.pem"
  region           = "eu-amsterdam-1"
}
variable "oracle_amd64_instances_names" {}
```

This goes along with a `terraform.tfvars` file that you should fill with the api access information you saved up earlier :
```hcl
oracle_tenancy_ocid = "XXXXX"
oracle_user_ocid    = "YYYYY"
oracle_fingerprint  = "ZZZZZ"

oracle_amd64_instances_names = ["dalinar", "kaladin"]
```

The last bit is how I name the two free instances I want to create, pick anything you like.

### Networking

Here is how to bootstrap a vcn and the associated objects for direct internet access. For simplicity I will leave the access lists opened, firewall rules really are a pain to write with terraform... I plan to keep on using iptables or shorewall on the hosts for now.
```hcl
resource "oci_core_vcn" "adyxax" {
  compartment_id = var.oracle_tenancy_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "adyxax"
  dns_label      = "adyxax"
  is_ipv6enabled = true
}
resource "oci_core_internet_gateway" "gw" {
  compartment_id = var.oracle_tenancy_ocid
  vcn_id         = oci_core_vcn.adyxax.id
  enabled        = true
  display_name   = "gw"
}
resource "oci_core_route_table" "default-via-gw" {
  compartment_id = var.oracle_tenancy_ocid
  vcn_id         = oci_core_vcn.adyxax.id
  display_name   = "default-via-gw"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.gw.id
  }
  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.gw.id
  }
}
# protocol - Specify either all or an IPv4 protocol number : ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58").·
resource "oci_core_security_list" "allow-all" {
  compartment_id = var.oracle_tenancy_ocid
  vcn_id         = oci_core_vcn.adyxax.id
  display_name   = "allow-all"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "::/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "::/0"
  }
}
resource "oci_core_subnet" "adyxax-production" {
  cidr_block     = cidrsubnet(oci_core_vcn.adyxax.cidr_blocks[0], 8, 0)
  compartment_id = var.oracle_tenancy_ocid
  vcn_id         = oci_core_vcn.adyxax.id

  display_name      = "production"
  dns_label         = "production"
  ipv6cidr_block    = cidrsubnet(oci_core_vcn.adyxax.ipv6cidr_blocks[0], 8, 0)
  security_list_ids = [oci_core_security_list.allow-all.id]
  route_table_id    = oci_core_route_table.default-via-gw.id
}
```

### Instances

Here is how to create the two always free tier instances, each in a different fault domain. The tricky part was to understand how ipv6 addresses are like second class citizens on oracle cloud :
```hcl
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oracle_tenancy_ocid
}
data "oci_identity_fault_domains" "fd" {
  compartment_id      = var.oracle_tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}
# taken from https://docs.oracle.com/en-us/iaas/images/all/?search=Oracle-Linux-8.4
data "oci_core_image" "ol8" {
  image_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaj46eslsa6ivgneyneypomtvzb6dmg22gtewy6opwiniuwgsdv7uq"
}

resource "oci_core_instance" "amd64-vms" {
  count                = length(var.oracle_amd64_instances_names)
  compartment_id       = var.oracle_tenancy_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  fault_domain         = data.oci_identity_fault_domains.fd.fault_domains[count.index % length(data.oci_identity_fault_domains.fd.fault_domains)].name
  display_name         = var.oracle_amd64_instances_names[count.index % length(var.oracle_amd64_instances_names)]
  shape                = "VM.Standard.E2.1.Micro"
  preserve_boot_volume = true
  create_vnic_details {
    subnet_id      = oci_core_subnet.adyxax-production.id
    hostname_label = var.oracle_amd64_instances_names[count.index]
    display_name   = var.oracle_amd64_instances_names[count.index]
  }
  source_details {
    boot_volume_size_in_gbs = 50
    source_type             = "image"
    source_id               = data.oci_core_image.ol8.id
  }
  metadata = {
    "ssh_authorized_keys" : "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOJV391WFRYgCVA2plFB8W8sF9LfbzXZOrxqaOrrwco"
  }
}
data "oci_core_vnic_attachments" "amd64-vms-vnics" {
  count          = length(var.oracle_amd64_instances_names)
  compartment_id = var.oracle_tenancy_ocid
  instance_id    = oci_core_instance.amd64-vms[count.index].id
}
resource "oci_core_ipv6" "amd64-vms-ipv6s" {
  count        = length(var.oracle_amd64_instances_names)
  vnic_id      = data.oci_core_vnic_attachments.amd64-vms-vnics[count.index].vnic_attachments[0].vnic_id
  display_name = var.oracle_amd64_instances_names[count.index]
}
```

### Bonus : Provisionning cloudflare's dns

If like me you are managing your dns with cloudflare, here is how to provision the relevant records :
```hcl
resource "cloudflare_record" "adyxax-org-oracle-amd64-vms-ipv4" {
  count   = length(var.oracle_amd64_instances_names)
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = var.oracle_amd64_instances_names[count.index]
  value   = oci_core_instance.amd64-vms[count.index].public_ip
  type    = "A"
  proxied = false
}
resource "cloudflare_record" "adyxax-org-oracle-amd64-vms-ipv6" {
  count   = length(var.oracle_amd64_instances_names)
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = var.oracle_amd64_instances_names[count.index]
  value   = oci_core_ipv6.amd64-vms-ipv6s[count.index].ip_address
  type    = "AAAA"
  proxied = false
}
```

## Conclusion

Putting all of this together was an interesting experience, and I am satisfied that it works well. In the future I plan to add my own oci image based on alpine linux which is not available natively. I tried oracle linux and it is fine, but consumes way too much ram for my taste. For now I installed alpine linux using the instance's cloud console and [my procedure for that]({{< ref "docs/alpine/remote_install_iso" >}}).
