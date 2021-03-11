---
title: "Get tls certificate and key from a kubernetes secret"
date: 2020-08-06
---

My use case is to deploy a wildcard certificate that was previously handled by an acme.sh on my legacy lxd containers. Since moving to kubernetes parts of my services I have been using cert-manager to issue letsencrypt certificates. Since I am not done yet I looked into a way of getting a certificate out of kubernetes. Assuming we are working with a secret named `wild.adyxax.org-cert` and our namespace is named `legacy` :
{{< highlight sh >}}
kubectl -n legacy get secret wild.adyxax.org-cert -o json -o=jsonpath="{.data.tls\.crt}" | base64 -d > fullchain.cer
kubectl -n legacy get secret wild.adyxax.org-cert -o json -o=jsonpath="{.data.tls\.key}" | base64 -d > adyxax.org.key
{{< /highlight >}}
