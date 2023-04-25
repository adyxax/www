---
title: Wireguard endpoint on kubernetes part 2
description: Implementation of last article's design
date: 2023-04-25
tags:
- kubernetes
- wireguard
---

## Introduction

This article details the implementation of the design from [the previous article]({{< ref "wireguard-endpoint-on-kubernetes-part-1.md" >}}). While not a requirement per se, I want to manage this wireguard deployment with terraform. All the services I deploy on kubernetes are managed this way, and I want to leverage it to write the proxy's configuration based on the services deployed.

## Basics

### Providers

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    external = {
      source = "hashicorp/external"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "cloudflare_adyxax_login" {}
variable "cloudflare_adyxax_api_key" {}

provider "cloudflare" {
  email   = var.cloudflare_adyxax_login
  api_key = var.cloudflare_adyxax_api_key
}

provider "kubernetes" {
  alias       = "myth"
  config_path = "../.kubeconfig-myth"
}
```

I explicitely use an alias for my kubernetes providers because I do not want to mistakenly apply an object to the default context that might be set when I run terraform.

### DNS record

I wrote all this configuration for use with k3s on `myth.adyxax.org`. My DNS is currently managed by cloudflare:
```hcl
data "cloudflare_zones" "adyxax-org" {
  filter {
    name = "adyxax.org"
  }
}

resource "cloudflare_record" "myth-wireguard-cname" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "wireguard"
  value   = "myth.adyxax.org"
  type    = "CNAME"
  proxied = false
}
```

### Namespace

I set labels on wireguard's namespace for network policy targeting:

```hcl
resource "kubernetes_namespace" "myth-wireguard" {
  provider = kubernetes.myth
  metadata {
    labels = local.wireguard-labels
    name = "wireguard"
  }
}
```

## Inventory

I define a `wireguard-inventory` map to hold where I input the information about the peers that are able to reach this cluster and the services that are exposed through wireguard. This information could be fed differently, for example by reading yaml files or fetching from an external datasource.

```hcl
locals {
  wireguard-inventory = {
    network = "10.1.3.16/28"
    # peers is a map indexed on the peers' ips. The name will be used by the prometheus exporter is you activate it.
    peers = {
      "10.1.2.4" = { name = "hero", pubkey = "IkeZeGnMasPnYmyR+xBUUfV9WrxphFwRJYbi2JhPjX0=" }
      "10.1.2.9" = { name = "yen", pubkey = "R4A01RXXqRJSY9TiKQrZGR85HsFNSXxhRKKEu/bEdTQ=" }
    }
    # services is a map of the kubernetes services exposed via wireguard, indexed on the ip offset to use. This is really
    # an offset and not an ip because it will be computed to an ip inside the network specified above.
    # values are arrays because I want to support listening on multiple ports for each ips
    services = {
      0 = [{
        dest = "kubernetes.default.svc.cluster.local:443"
        name = "kubernetes"
        port = 443
      }]
      1 = [{
        dest = "postgresql.postgresql.svc.cluster.local:5432"
        name = "postgresql"
        port = 5432
      }]
    }
  }
}
```

## Wireguard

### Keys

The host key is generated randomly and I use an external datasource to compute the public key:
```hcl
resource "random_password" "wireguard-private-key" {
  length  = 32
  special = true
}

data "external" "wireguard-public-key" {
  program = ["bash", "-c", "printf '${base64encode(random_password.wireguard-private-key.result)}' | wg pubkey | jq -Rnc '{pubkey:input}'"]
}
```

### Templates

I have three template files living in a `wireguard` subfolder of this terraform folder.

#### Pre-requisites

We need to take the `wireguard-inventory` map and augment it with some more information that we feed to our templates:
```hcl
locals {
  wireguard-labels = {
    app = "wireguard"
  }
  # This is the map that is passed to all template files
  wireguard = merge(local.wireguard-inventory, {
    private-key = base64encode(random_password.wireguard-private-key.result)
    public-key  = data.external.wireguard-public-key.result.pubkey
    # services is now a map indexed on the services ips
    services = { for i, svc in local.wireguard-inventory.services : cidrhost(local.wireguard-inventory.network, i) => svc }
  })
}
```

#### init.sh

I am mounting an init script into a base alpine linux image. It is not the way I do containers for normal services, but in this case for a simple infrastructure component I find it is better to have one less container image to maintain.
```sh
#!/bin/sh
set -euo pipefail

apk add --no-cache \
    iproute2 \
    nginx \
    nginx-mod-stream \
    wireguard-tools \
    1>/dev/null

# We need to guard these commands in case nginx crashloops, we would end up with
# RTNETLINK answers: File exists errors. This is because kubernetes restarts the
# command of a failed container without recreating it completely so the network
# is already setup when we reach this point.
ip link add wg0 type wireguard || true
%{ for ip, svc in w.services ~}
ip address add ${ip}/32 dev wg0 || true
%{ endfor }
ip link set wg0 up
%{ for ip, peer in w.peers ~}
ip route add ${ip}/32 dev wg0 || true
%{ endfor }

wg setconf wg0 /wireguard/wg0.cfg

exec /usr/sbin/nginx -c /wireguard/nginx.cfg
```

#### nginx.cfg

I use nginx as a tcp proxy using its stream module. It drops its privileges after starting:
```nginx
daemon off;
user nobody;
load_module /usr/lib/nginx/modules/ngx_stream_module.so;
error_log /dev/stdout info;
events {
	worker_connections 1024;
}
stream {
	# Setting a variable deactivates nginx static evaluation of the
	# proxy_pass target, instructing it to resolve the target only when
	# the proxy_pass is triggered by a new connection. This is a behaviour
	# we need otherwise a failed dns resolution prevents nginx to start or
	# to reload its configuration.
	#
	# A timeout of 60 seconds for nginx's dns cache seems a good balance
	# between performance (we do not want to trigger a dns resolution on
	# every request) and safety (we do not want to cache bad records for
	# too long when terraform provisions or changes things).
	resolver kube-dns.kube-system.svc.cluster.local valid=60s;

	%{~ for ip, service in w.services ~}
	%{~ for svc in service ~}
	server {
		# ${svc["name"]}
		listen ${ip}:${svc["port"]};
		set $backend "${svc["dest"]}";
		proxy_pass $backend;
	}
	%{~ endfor ~}
	%{~ endfor ~}
}
```

#### wg0.cfg

If you followed the previous articles, this wireguard configuration must be very familiar by now:
```cfg
[Interface]
PrivateKey = ${w.private-key}
ListenPort = 342

%{ for ip, peer in w.peers ~}
[Peer]
# friendly_name = ${peer["name"]}
PublicKey = ${peer["pubkey"]}
AllowedIPs = ${ip}/32
%{ endfor ~}
```

### Config map

This config map holds the three templates we just defined:
```hcl
resource "kubernetes_config_map" "wireguard" {
  provider = kubernetes.myth
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.wireguard.metadata.0.name
  }
  data = {
    "init.sh"   = templatefile("wireguard/init.sh", { w = local.wireguard })
    "nginx.cfg" = templatefile("wireguard/nginx.cfg", { w = local.wireguard })
    "wg0.cfg"   = templatefile("wireguard/wg0.cfg", { w = local.wireguard })
  }
}

```

### Stateful set

I am using a stateful set because I like having a predictable name for pods that will be forever alone, but if you do not mind the random string after a pod's name a simple deployment would do:
```hcl
resource "kubernetes_stateful_set" "wireguard" {
  provider = kubernetes.myth
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.wireguard.metadata.0.name
  }
  spec {
    service_name = "wireguard"
    replicas = 1
    selector {
      match_labels = local.wireguard-labels
    }
    template {
      metadata {
        annotations = {
          config_change = sha1(jsonencode(
            kubernetes_config_map.wireguard.data
          ))
        }
        labels = local.wireguard-labels
      }
      spec {
        container {
          command = ["/bin/sh", "-c", "/wireguard/init.sh"]
          image   = "alpine:latest"
	  image_pull_policy = "Always"
          name    = "wireguard-nginx"
          port {
            container_port = "342"
            name           = "wireguard"
            protocol       = "UDP"
          }
          resources {
            requests = {
              cpu    = "10m"
              memory = "15Mi"
            }
          }
          security_context {
            capabilities {
              add = ["NET_ADMIN"]
            }
          }
          volume_mount {
            mount_path = "/wireguard"
            name       = "wireguard"
          }
        }
        volume {
          name = "wireguard"
          config_map {
            default_mode = "0777"
            name         = kubernetes_config_map.wireguard.metadata.0.name
          }
        }
      }
    }
  }
}
```

Notice the annotation that ensures the pod will restart if terraform updates the config map.

### Service

I am using a NodePort service because I am running k3s and want to be able to connect to any kubernetes node and have my vpn work, but if you are running this on a cloud provider's network you might want a service of type `Loadbalancer` instead:
```hcl
resource "kubernetes_service" "wireguard" {
  provider = kubernetes.myth
  metadata {
    name      = "wireguard"
    namespace = kubernetes_namespace.wireguard.metadata.0.name
  }
  spec {
    type     = "NodePort"
    selector = local.wireguard-labels
    port {
      port        = 342
      protocol    = "UDP"
      target_port = 342
    }
  }
}

```

## Network policies

If you are using network policies (and you should) for the namespaces of the services you wish to expose via wireguard, you will need to deploy objects like the following in each of these namespaces:
```hcl
resource "kubernetes_network_policy" "wireguard-postgresql" {
  provider = kubernetes.myth
  metadata {
    name      = "allow-from-wireguard"
    namespace = "postgresql"
  }

  spec {
    ingress {
      from {
        namespace_selector {
          match_labels = local.wireguard-labels
        }
        pod_selector {
          match_labels = local.wireguard-labels
        }
      }
    }
    pod_selector {}
    policy_types = ["Ingress"]
  }
}
```

If you are not using network policies (you really should) in a namespace, DO NOT create these objects or you will lose connectivity to these namespaces. Kubernetes behaviour when there are no network policies in place in to allow everything, but as soon as the a network policy is created and selects a pod then only traffic that matches it will be allowed. You have been warned!

## Exporting the connection information

This allows me to write the configuration of clients that will connect to this cluster:
```hcl
resource "local_file" "wireguard-generated-configuration-myth" {
  filename        = "wireguard-generated-configuration-myth.yaml"
  file_permission = "0600"
  content = yamlencode({
    network = local.wireguard.network
    port    = kubernetes_service.wireguard.spec.0.port.0.node_port
    pubkey  = local.wireguard.public-key
  })
}
```

## Conclusion

This article has been a long time coming, I have been using this setup in my personal production for almost two years now. If you have questions or comments, you can write me an email at `julien -DOT- dessaux -AT- adyxax -DOT- org`. I will also respond on Mastodon/ActivityPub at `@adyxax@adyxax.org`.