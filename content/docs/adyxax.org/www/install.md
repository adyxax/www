---
title: "Installation"
description: Installation notes of www on k3s
tags:
- hugo
- k3s
- kubernetes
---

## Introduction

This is a static website built using hugo.

The CI/CD is a work in progress, for now the installation is made from a crude kubernetes manifest. The instructions have been updated for the search feature.

## Kubernetes manifests

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: www
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: www
  name: www
  labels:
    app: www
spec:
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  selector:
    matchLabels:
      app: www
  template:
    metadata:
      labels:
        app: www
    spec:
      containers:
      - name: www
        image: quay.io/adyxax/www:2021110901
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: '/'
            port: 80
          initialDelaySeconds: 1
          timeoutSeconds: 1
        livenessProbe:
          httpGet:
            path: '/'
            port: 80
          initialDelaySeconds: 1
          timeoutSeconds: 1
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 10"]
      - name: search
        image: quay.io/adyxax/www-search:2021110901
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: '/search/'
            port: 8080
          initialDelaySeconds: 1
          timeoutSeconds: 1
        livenessProbe:
          httpGet:
            path: '/search/'
            port: 8080
          initialDelaySeconds: 1
          timeoutSeconds: 1
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 10"]
---
apiVersion: v1
kind: Service
metadata:
  namespace: www
  name: www
spec:
  type: ClusterIP
  selector:
    app: www
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      name: www
    - protocol: TCP
      port: 8080
      targetPort: 8080
      name: search
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: www
  name: www
spec:
  ingressClassName: nginx
  tls:
  - secretName: wildcard-adyxax-org
  rules:
  - host: www.adyxax.org
    http:
      paths:
      - path: '/'
        pathType: Prefix
        backend:
          service:
            name: www
            port:
              number: 80
      - path: '/search'
        pathType: Prefix
        backend:
          service:
            name: www
            port:
              number: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: www
  name: redirects
  annotations:
    nginx.ingress.kubernetes.io/permanent-redirect: https://www.adyxax.org/
    nginx.ingress.kubernetes.io/permanent-redirect-code: "308"
spec:
  ingressClassName: nginx
  tls:
  - secretName: wildcard-adyxax-org
  rules:
  - host: adyxax.org
  - host: wiki.adyxax.org
```

## DNS CNAME

Terraform is only used for the dns record on this app for legacy reasons

```hcl
resource "cloudflare_record" "pass-cname" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "www"
  value   = "myth.adyxax.org"
  type    = "CNAME"
  proxied = false
}
```

## Certificate

For now I do not manage my certificates with terraform but manually. Once every two months I run :
```sh
acme.sh --config-home "$HOME/.acme.sh" --server letsencrypt --dns dns_cf --issue -d adyxax.org -d *.adyxax.org --force
kubectl -n www create secret tls wildcard-adyxax-org --cert=$HOME/.acme.sh/adyxax.org/fullchain.cer \
  --key=$HOME/.acme.sh/adyxax.org/adyxax.org.key -o yaml --save-config --dry-run=client | kubectl apply -f -
```
