---
title: Terraform refactoring and state move
description: An example replacing a count with a for_each
date: 2022-01-03
tags:
  - terraform
---

## Introduction

When I initialised my oracle cloud free tier infrastructure in [a previous blog article]({{< ref "getting_started_oci_free_tier.md" >}}), I made a mistake of using a `count` to iterate on a list of names for the instances I wished to spawn. The drawback of doing this is that I cannot reorder the items in this list, and deleting one instance could affect the other.

The solution to this is to change this `count` construct to a `for_each`. This way the state objects will no longer be indexed by the instance position in the list, they will be indexed by their names.

## What changes in the terraform code

Since in one of the resources I used the index to infer a fault domain id, I rewrote the list from this :
```hcl
oracle_amd64_instances_names = ["dalinar", "kaladin"]
```

to this :
```hcl
oracle_amd64_instances = {
  dalinar = { "fault_domain_id" = 0 },
  kaladin = { "fault_domain_id" = 1 },
}
```

Note that I renamed the variable in order to not miss anywhere it was used. Now for each resource that used this list with a `count` like the following :
```hcl
resource "oci_core_instance" "amd64-vms" {
  count                = length(var.oracle_amd64_instances_names)
  compartment_id       = var.oracle_tenancy_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  fault_domain         = data.oci_identity_fault_domains.fd.fault_domains[
    count.index % length(data.oci_identity_fault_domains.fd.fault_domains)].name
  display_name         = var.oracle_amd64_instances_names[
    count.index % length(var.oracle_amd64_instances_names)]
  shape                = "VM.Standard.E2.1.Micro"
  preserve_boot_volume = false
  create_vnic_details {
    subnet_id      = oci_core_subnet.adyxax-production.id
    hostname_label = var.oracle_amd64_instances_names[count.index]
    display_name   = var.oracle_amd64_instances_names[count.index]
}
```

Such entries now becomes :
```hcl
resource "oci_core_instance" "amd64-vms" {
  for_each             = var.oracle_amd64_instances
  compartment_id       = var.oracle_tenancy_ocid
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  fault_domain         = data.oci_identity_fault_domains.fd.fault_domains[each.value["fault_domain_id"]].name
  display_name         = each.key
  shape                = "VM.Standard.E2.1.Micro"
  preserve_boot_volume = false
  create_vnic_details {
    subnet_id      = oci_core_subnet.adyxax-production.id
    hostname_label = each.key
    display_name   = each.key
}
```

## How to migrate the state

To see which resources need to be migrated you can use `terraform state list` :
```sh
julien@nas ~/git/adyxax/adyxax.org/02-permanent-hosts (master *$%) $ terraform state list
data.cloudflare_zones.adyxax-eu
data.cloudflare_zones.adyxax-org
data.cloudflare_zones.asj-fr
data.hcloud_ssh_key.adyxax
data.oci_core_image.ol8
data.oci_core_vnic_attachments.amd64-vms-vnics[0]
data.oci_core_vnic_attachments.amd64-vms-vnics[1]
data.oci_identity_availability_domains.ads
data.oci_identity_fault_domains.fd
cloudflare_record.adyxax-org-oracle-amd64-vms-ipv4[0]
cloudflare_record.adyxax-org-oracle-amd64-vms-ipv4[1]
cloudflare_record.adyxax-org-oracle-amd64-vms-ipv6[0]
cloudflare_record.adyxax-org-oracle-amd64-vms-ipv6[1]
oci_core_instance.amd64-vms[0]
oci_core_instance.amd64-vms[1]
oci_core_internet_gateway.gw
oci_core_ipv6.amd64-vms-ipv6s[0]
oci_core_ipv6.amd64-vms-ipv6s[1]
oci_core_route_table.default-via-gw
oci_core_security_list.allow-all
oci_core_subnet.adyxax-production
oci_core_vcn.adyxax
```

Here we are interested with all the resources indexed with `0` and `1`. I migrated the state using the following commands :
```sh
terraform state mv data.oci_core_vnic_attachments.amd64-vms-vnics[0] \
                   data.oci_core_vnic_attachments.amd64-vms-vnics[\"dalinar\"]
terraform state mv data.oci_core_vnic_attachments.amd64-vms-vnics[1] \
                   data.oci_core_vnic_attachments.amd64-vms-vnics[\"kaladin\"]
terraform state mv cloudflare_record.adyxax-org-oracle-amd64-vms-ipv4[0] \
                   cloudflare_record.adyxax-org-oracle-amd64-vms-ipv4[\"dalinar\"]
terraform state mv cloudflare_record.adyxax-org-oracle-amd64-vms-ipv4[1] \
                   cloudflare_record.adyxax-org-oracle-amd64-vms-ipv4[\"kaladin\"]
terraform state mv cloudflare_record.adyxax-org-oracle-amd64-vms-ipv6[0] \
                   cloudflare_record.adyxax-org-oracle-amd64-vms-ipv6[\"dalinar\"]
terraform state mv cloudflare_record.adyxax-org-oracle-amd64-vms-ipv6[1] \
                   cloudflare_record.adyxax-org-oracle-amd64-vms-ipv6[\"kaladin\"]
terraform state mv oci_core_instance.amd64-vms[0] \
                   oci_core_instance.amd64-vms[\"dalinar\"]
terraform state mv oci_core_instance.amd64-vms[1] \
                   oci_core_instance.amd64-vms[\"kaladin\"]
terraform state mv oci_core_ipv6.amd64-vms-ipv6s[0] \
                   oci_core_ipv6.amd64-vms-ipv6s[\"dalinar\"]
terraform state mv oci_core_ipv6.amd64-vms-ipv6s[1] \
                   oci_core_ipv6.amd64-vms-ipv6s[\"kaladin\"]
```

Note the escaping of the quotes so that the shell does not interpret (and remove) these. We can make sure we did not do any mistake by running a plan and seeing that terraform does not report any changes :
```sh
No changes. Your infrastructure matches the configuration.
```
