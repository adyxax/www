---
title: Making dual stack ipv6 work with k3s
date: 2021-07-27
description: How to setup a working ipv4/ipv6 service on k3s
tags:
  - ipv6
  - k3s
  - kubernetes
---

## Introduction

I have yet to write a lot about the kubernetes setup I use for pieces of my personal infrastructure, because I was not satisfied with what I had to show. Today I picked up k3s again which I like quite a lot for it being a light implementation. Consuming 800M of ram before you get any workload running is hardly lightweight, but it is the lightest I have experienced for kubernetes. An entry level virtual machine at ovh or hetzner having 2G of ram for 3€/month is sufficient to run it, that's what I have been doing for the last year.

The main thing I was not satisfied was ipv6 support. I do not know what changed since last year when I tried and failed to make it work in k3s 1.19, but now with 1.21 and some effort it does work! Here is how.

## Installation

Let's start with a freshly reinstalled ovh vps with Ubuntu 20.04. Make sure to properly configure ipv6 on it, for this ovh machine I configured a netplan that looks like this :
```yaml
network:
    version: 2
    ethernets:
        ens3:
            dhcp4: true
            match:
                macaddress: fa:16:3e:82:71:b7
            mtu: 1500
            set-name: ens3
            dhcp6: no
            addresses:
                - 2001:41d0:401:3100:0:0:0:fd5/128
            gateway6: 2001:41d0:0401:3100:0000:0000:0000:0001
            routes:
                - to: 2001:41d0:0401:3100:0000:0000:0000:0001
                  scope: link
```

After installation I just ran an `apt dist-upgrade` then installed `ipvsadm`. Afterwards it's all k3s :
```sh
export INSTALL_K3S_VERSION=v1.21.3+k3s1
export INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --disable metrics-server --disable-cloud-controller \
       --kube-proxy-arg proxy-mode=ipvs --cluster-cidr=10.42.0.0/16,fd42::/48 --service-cidr=10.43.0.0/16,fd43::/112 \
       --disable-network-policy --flannel-backend=none --node-ip=37.187.244.19,2001:41d0:401:3100::fd5"
```

As you can see we need to disable quite a few k3s components, mainly flannel which does not support dual stack at all at this time (it has been coming soon© to flannel for quite some time) and servicelb (the internal component to k3s which allows to simply use the LoadBalancer service type). We are going to use Calico instead of flannel therefore we also disable k3s' internal network policy system, and we are going to need to customize the ingress service so we also disable the integrated traefik. We will use metallb instead of servicelb and ingress-nginx instead of traefik.

If you are replicating this on your own setup make sure the node-ip addresses are the ones configured on your node, if the cluster-cidr and service-cidr do not conflict with your own you can keep those.

Once ready review the k3s installation script then run it :
```sh
wget https://get.k3s.io -O k3s.sh
less k3s.sh
bash k3s.sh
```

With k3s installed you should be able to access the kubernetes cli with `kubectl get nodes` but basic services like coredns pod won't start before calico is setup.

## Calico

Retrieve Calico's manifests with :
```sh
wget https://docs.projectcalico.org/manifests/calico.yaml
```

Edit this file and locate the `ipam` section of the ConfigMap. Change it to the following :
```json
"ipam": {
    "type": "calico-ipam",
    "assign_ipv4": "true",
    "assign_ipv6": "true"
},
```

Then locate the `FELIX_IPV6SUPPORT` variable in the calico-node DaemonSet configuration and set it to `true`.

You can then apply this manifest :
```sh
kubectl apply -f calico.yaml
```

From there for standard pods and services should start properly, give calico some time and check :
```
kubectl get pods -A
NAMESPACE     NAME                                           READY   STATUS    RESTARTS   AGE
kube-system   pod/local-path-provisioner-5ff76fc89d-5xvcg    1/1     Running   0          2m51s
kube-system   pod/calico-node-dfwp5                          1/1     Running   0          67s
kube-system   pod/coredns-7448499f4d-ckzlk                   1/1     Running   0          2m51s
kube-system   pod/calico-kube-controllers-78d6f96c7b-m527n   1/1     Running   0          67s
```

You should have four pods running : coredns, two calico pods and k3s' local path provisionner.

## Metallb

Since this is a cheap and self made infrastructure we are going to rely on metallb to provide us with external connectivity. Install it with :
```sh
wget https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml -O metallb-namespace.yaml
wget https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml -O metallb-0.10.2-manifest.yaml
kubectl apply -f metallb-namespace.yaml -f metallb-0.10.2-manifest.yaml
```

Then create a metallb-config.yaml with content like this :
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 37.187.244.19/32
      - 2001:41d0:401:3100::fd5/128
```

Don't forget to replace the ipv4 and ipv6 addresses with the ones configured on your node. Then apply this manifest :
```sh
kubectl apply -f metallb-config.yaml
```

Give it a minute then check that everything is ok :
```sh
kubectl -n metallb-system get pods
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-6b78bff7d9-szz78   1/1     Running   0          86s
pod/speaker-mx46m                 1/1     Running   0          86s
```

## Ingress-nginx

From there we can setup our ingress-nginx, but it will require a bit of service customization :
```sh
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.48.1/deploy/static/provider/baremetal/deploy.yaml \
     -O ingress-nginx-0.48.1.yaml
```

Edit this file and locate the ingress-nginx-controller Service, which is by default of type NodePort. We are going to replace it with two services of type LoadBalancer, one for ipv4 and one for ipv6. Theoretically a single DualStack service should be supported but it does not work for me, the service only listens on its ipv6 address. So we are going to replace the whole ingress-nginx-controller Service with these two entries :
```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    helm.sh/chart: ingress-nginx-3.34.0
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/version: 0.48.1
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
  name: ingress-nginx-controller-v4
  namespace: ingress-nginx
spec:
  type: LoadBalancer
  ipFamilies:
    - IPv4
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
    - name: https
      port: 443
      protocol: TCP
      targetPort: https
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
---
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    helm.sh/chart: ingress-nginx-3.34.0
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/version: 0.48.1
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
  name: ingress-nginx-controller-v6
  namespace: ingress-nginx
spec:
  type: LoadBalancer
  ipFamilies:
    - IPv6
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
    - name: https
      port: 443
      protocol: TCP
      targetPort: https
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
```

Note the metadata names with `-v4` and `-v6` suffixes, the `type: LoadBalancer` and the respective ipFamilies. You can now apply this manifest :
```sh
kubectl apply -f ingress-nginx-0.48.1.yaml
```

Give it some time, then check that the two controller services each get the ipv4 or ipv6 address of your node :
```sh
kubectl -n ingress-nginx get pods,svc
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-hcgdm        0/1     Completed   0          52s
pod/ingress-nginx-admission-patch-hl2vw         0/1     Completed   1          52s
pod/ingress-nginx-controller-5cb8d9c6dd-5692s   1/1     Running     0          52s

NAME                                         TYPE           CLUSTER-IP      EXTERNAL-IP               PORT(S)                      AGE
service/ingress-nginx-controller-admission   ClusterIP      10.43.244.41    <none>                    443/TCP                      37s
service/ingress-nginx-controller-v4          LoadBalancer   10.43.139.251   37.187.244.19             80:31501/TCP,443:32318/TCP   37s
service/ingress-nginx-controller-v6          LoadBalancer   fd43::2a99      2001:41d0:401:3100::fd5   80:31923/TCP,443:30428/TCP   36s
```

## Conclusion

Now you can deploy your own services, personally I am going to migrate this blog then my privatebin and miniflux instances and see if it is reliable.
