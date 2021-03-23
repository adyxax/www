---
title: OpenBSD relayd/httpd web server example
date: 2021-02-10
description: a detailed answer to a question on reddit
tags:
  - OpenBSD
---

## Introduction

[Someone on reddit had trouble](https://www.reddit.com/r/openbsd/comments/lh4yl9/relaydhttpd_reverse_proxy_for_synapse_with/) with how `relayd` and `httpd` work together on OpenBSD. Those are two great components of the OpenBSD base system that take a different approach than the traditional web servers like `Nginx` or `Apache`, I wrote a complete example adapted from my own working configurations.

The goal was to have a relayd configuration that would serve urls like `https://example.com/` with the static website content from httpd, and proxy traffic to urls like https://chat.example.com/ to a synapse server running on `localhost:8008`. Hopefully my working example can provide a better understanding of the idea behind the couple relayd/httpd.

## The httpd configuration

{{< highlight txt >}}
prefork 5

server "example.com" {
    alias "chat.example.com"
    listen on * port 80
    location "/.well-known/acme-challenge/*" {
            root "/acme"
            request strip 2
    }
    location * {
            block return 301 "https://$HTTP_HOST$REQUEST_URI"
    }
}

server "example.com" {
    listen on * port 8080
    location * {
            root "/htdocs/www/public/"
    }
}
{{< /highlight >}}

## The relayd configuration

{{< highlight txt >}}
log state changes
log connection errors
prefork 5

table <httpd> { 127.0.0.1 }
table <synapse> { 127.0.0.1 }

http protocol "wwwsecure" {
    tls keypair "example.com"
    tls keypair "chat.example.com"

    # Return HTTP/HTML error pages to the client
    return error
    # you may want to remove this depending on your use case
    #match request header set "Connection" value "close"

    # your web application might need these headers
    match request header set "X-Forwarded-For" value "$REMOTE_ADDR"
    match request header set "X-Forwarded-By" value "$SERVER_ADDR:$SERVER_PORT"

    # set best practice security headers
    # use https://securityheaders.com to check
    # and modify as needed
    match response header remove "Server"
    match response header append "Strict-Transport-Security" value "max-age=31536000; includeSubDomains"
    match response header append "X-Frame-Options" value "SAMEORIGIN"
    match response header append "X-XSS-Protection" value "1; mode=block"
    match response header append "X-Content-Type-Options" value "nosniff"
    match response header append "Referrer-Policy" value "strict-origin"
    match response header append "Content-Security-Policy" value "default-src https:; style-src 'self' \
      'unsafe-inline'; font-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
    match response header append "Permissions-Policy" value "accelerometer=(none), camera=(none), \
      geolocation=(none), gyroscope=(none), magnetometer=(none), microphone=(none), payment=(none), usb=(none)"

    # set recommended tcp options
    tcp { nodelay, sack, socket buffer 65536, backlog 100 }

    pass  request  quick  header  "Host"  value  "example.com"       forward  to  <httpd>
    pass  request  quick  header  "Host"  value  "chat.example.com"  forward  to  <synapse>
}

relay "wwwsecure" {
    listen on 0.0.0.0 port 443 tls
    protocol wwwsecure
    forward to <httpd> port 8080
    forward to <synapse> port 8008
}
relay "wwwsecure6" {
    listen on :: port 443 tls
    protocol wwwsecure
    forward to <httpd> port 8080
    forward to <synapse> port 8008
}
{{< /highlight >}}
