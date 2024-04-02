---
title: A french scrabble web validator
description: a good use for a golang static binary deployed on nixos
date: 2024-04-03
tags:
- golang
---

## Introduction

After seeing my parents use mobile applications full of ads just to check if a word is valid to play in the famous scrabble game (french version), I decided I could do something about it. This is a few hours project to build and deploy a small web application with just an input form and a backend that checks if words are valid or not. It is also an opportunity to look into go 1.22 stdlib routing improvements.

## The project

### The dictionary

The "Officiel Du Scrabble" (ODS for short) is what the official dictionary for this game is called. One very sad thing is that this dictionary is not free! You cannot download it digitally, which seems crazy for a simple list of words. You might use your google-fu and maybe find it on some random GitHub account if you look for it, but I certainly did not.

### The web service

Here is what I have to say about this [80 lines go program](https://git.adyxax.org/adyxax/ods/tree/main.go):
- The first lines are the necessary imports.
- The next ones are dedicated to embedding all the files into a single binary.
- The compilation of the HTML template follows, with the definition of a struct type necessary for its rendering.
- Then come the two http handlers.
- Finally the main function that defines the http routes and starts the server.

While it does not feel optimal in terms of validation since I am not parsing the users' input, this input is normalized: accents and diacritics are converted to the corresponding ASCII character and spaces are trimmed at the beginning and at the end of the input. Then it is a simple matter of comparing strings while iterating over the full list of words.

Building a trie would make the search a lot faster, but the simplest loop takes less than 2ms on my server and therefore is good enough for a service that will barely peak at a few requests per minutes.

### Hosting

I build a static binary with `CGO_ENABLED=0 go build -ldflags "-s -w -extldflags \"-static\"" .` and since there is no `/usr/local` on nixos I simply copy this static binary to `/srv/ods/ods`. The nixos way would be to write a derivation but I find it too unwieldily for such a simple use case.

Here is the rest of the relevant configuration:

``` nix
{ config, lib, pkgs, ... }:
{
        imports = [
          ../lib/nginx.nix
        ];
        services.nginx.virtualHosts =  let
          headersSecure = ''
            # A+ on https://securityheaders.io/
            add_header X-Frame-Options deny;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Content-Type-Options nosniff;
            add_header Referrer-Policy strict-origin;
            add_header Cache-Control no-transform;
            add_header Content-Security-Policy "script-src 'self' 'unsafe-inline'";
            add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()";
            # 6 months HSTS pinning
            add_header Strict-Transport-Security max-age=16000000;
          '';
          headersStatic = headersSecure + ''
            add_header Cache-Control "public, max-age=31536000, immutable";
          '';
        in {
                "ods.adyxax.org" = {
                  extraConfig = "error_page  404  /404.html;";
                  forceSSL = true;
                  locations = {
                    "/" = {
                      extraConfig = headersSecure;
                      proxyPass = "http://127.0.0.1:8090";
                    };
                    "/static" = {
                      extraConfig = headersStatic;
                      proxyPass = "http://127.0.0.1:8090";
                    };
                  };
                  sslCertificate = "/etc/nginx/adyxax.org.crt";
                  sslCertificateKey = "/etc/nginx/adyxax.org.key";
                };
        };
        systemd.services."ods" = {
                description = "ods.adyxax.org service";

                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                wantedBy = [ "multi-user.target" ];

                serviceConfig = {
                        ExecStart = "/srv/ods/ods";
                        Type = "simple";
                        DynamicUser = "yes";
                };
        };
}
```

This defines a nginx virtual host that proxifies requests to our service, along with a systemd unit that will ensure our service is running.

### DNS

My DNS records are set via OpenTofu (terraform) and look like:

``` hcl
resource "cloudflare_record" "ods-cname-adyxax-org" {
  zone_id = lookup(data.cloudflare_zones.adyxax-org.zones[0], "id")
  name    = "ods"
  value   = "myth.adyxax.org"
  type    = "CNAME"
  proxied = false
}
```

## Conclusion

This was a fun little project, it is live at https://ods.adyxax.org/. Go really is a good choice for such self contained little web services.
