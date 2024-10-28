---
title: 'Nginx ansible role'
description: 'The ansible role I use to manage my nginx web servers'
date: '2024-10-28'
tags:
- ansible
- nginx
---

## Introduction

Before succumbing to nixos, I had been using an ansible role to manage my nginx web servers. Now that I am in need of it again I refined it a bit: here is the result.

## The role

### Vars

The role has OS specific vars in files named after the operating system. For example in `vars/Debian.yaml` I have:

``` yaml
---
nginx:
  etc_dir: '/etc/nginx'
  pid_file: '/run/nginx.pid'
  www_user: 'www-data'
```

While in `vars/FreeBSD.yaml` I have:

``` yaml
---
nginx:
  etc_dir: '/usr/local/etc/nginx'
  pid_file: '/var/run/nginx.pid'
  www_user: 'www'
```

### Tasks

The main tasks file setups nginx and the global configuration common to all virtual hosts:

``` yaml
---
- include_vars: '{{ ansible_distribution }}.yaml'

- name: 'Install nginx'
  package:
    name:
      - 'nginx'

- name: 'Make nginx vhost directory'
  file:
    path: '{{ nginx.etc_dir }}/vhost.d'
    mode: '0755'
    owner: 'root'
    state: 'directory'

- name: 'Deploy nginx configuration files'
  copy:
    src: '{{ item }}'
    dest: '{{ nginx.etc_dir }}/{{ item }}'
  notify: 'reload nginx'
  loop:
    - 'headers_base.conf'
    - 'headers_secure.conf'
    - 'headers_static.conf'
    - 'headers_unsafe_inline_csp.conf'

- name: 'Deploy nginx configuration template'
  template:
    src: 'nginx.conf'
    dest: '{{ nginx.etc_dir }}/'
  notify: 'reload nginx'

- name: 'Deploy nginx certificates'
  copy:
    src: '{{ item }}'
    dest: '{{ nginx.etc_dir }}/'
  notify: 'reload nginx'
  loop:
    - 'adyxax.org.fullchain'
    - 'adyxax.org.key'
    - 'dh4096.pem'

- name: 'Start nginx and activate it on boot'
  service:
    name: 'nginx'
    enabled: true
    state: 'started'
```

I have a `vhost.yaml` task file which currently simply deploys a file and reload nginx:

``` yaml
- name: 'Deploy {{ vhost.name }} vhost {{ vhost.path }}'
  template:
    src: '{{ vhost.path }}'
    dest: '{{ nginx.etc_dir }}/vhost.d/{{ vhost.name }}.conf'
  notify: 'reload nginx'
```

### Handlers

There is a single `main.yaml` handler:

``` yaml
---
- name: 'reload nginx'
  service:
    name: 'nginx'
    state: 'reloaded'
```

### Files

I deploy four configuration files in this role. These are all variants of the same theme and their purpose is just to prevent duplicating statements in the virtual hosts configuration files.

`headers_base.conf`:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

add_header X-Frame-Options deny;
add_header X-XSS-Protection "1; mode=block";
add_header X-Content-Type-Options nosniff;
add_header Referrer-Policy strict-origin;
add_header Cache-Control no-transform;
add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()";
# 6 months HSTS pinning
add_header Strict-Transport-Security max-age=16000000;
```

`headers_secure.conf`:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

include headers_base.conf;
add_header Content-Security-Policy "script-src 'self'";
```

`headers_static.conf`:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

include headers_secure.conf;
# Infinite caching
add_header Cache-Control "public, max-age=31536000, immutable";
```

`headers_unsafe_inline_csp.conf`:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

include headers_base.conf;
add_header Content-Security-Policy "script-src 'self' 'unsafe-inline'";
```

### Templates

I have a single template for `nginx.conf`:

``` nginx
###############################################################################
#     \_o<     WARNING : This file is being managed by ansible!      >o_/     #
#     ~~~~                                                           ~~~~     #
###############################################################################

user {{ nginx.www_user }};
worker_processes  auto;
pid {{ nginx.pid_file }};
error_log /var/log/nginx/error.log;

events {
    worker_connections  1024;
}

http {
    include              mime.types;
    types_hash_max_size  4096;
    sendfile             on;
    tcp_nopush           on;
    tcp_nodelay          on;
    keepalive_timeout    65;

    ssl_protocols  TLSv1.2 TLSv1.3;
    ssl_ciphers    ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;

    gzip             on;
    gzip_static      on;
    gzip_vary        on;
    gzip_comp_level  5;
    gzip_min_length  256;
    gzip_proxied     expired  no-cache  no-store  private  auth;
    gzip_types  application/atom+xml  application/geo+json  application/javascript  application/json  application/ld+json  application/manifest+json  application/rdf+xml  application/vnd.ms-fontobject  application/wasm  application/x-rss+xml  application/x-web-app-manifest+json  application/xhtml+xml  application/xliff+xml  application/xml  font/collection  font/otf  font/ttf  image/bmp  image/svg+xml  image/vnd.microsoft.icon  text/cache-manifest  text/calendar  text/css  text/csv  text/javascript  text/markdown  text/plain  text/vcard  text/vnd.rim.location.xloc  text/vtt  text/x-component  text/xml;

    proxy_redirect         off;
    proxy_connect_timeout  60s;
    proxy_send_timeout     60s;
    proxy_read_timeout     60s;
    proxy_http_version     1.1;
    proxy_set_header       "Connection"        "";
    proxy_set_header       Host                $host;
    proxy_set_header       X-Real-IP           $remote_addr;
    proxy_set_header       X-Forwarded-For     $proxy_add_x_forwarded_for;
    proxy_set_header       X-Forwarded-Proto   $scheme;
    proxy_set_header       X-Forwarded-Host    $host;
    proxy_set_header       X-Forwarded-Server  $host;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    client_max_body_size  40M;
    server_tokens         off;
    default_type          application/octet-stream;
    access_log            /var/log/nginx/access.log;

    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    fastcgi_param  QUERY_STRING     $query_string;
    fastcgi_param  REQUEST_METHOD   $request_method;
    fastcgi_param  CONTENT_TYPE     $content_type;
    fastcgi_param  CONTENT_LENGTH   $content_length;

    fastcgi_param  SCRIPT_NAME      $fastcgi_script_name;
    fastcgi_param  REQUEST_URI      $request_uri;
    fastcgi_param  DOCUMENT_URI     $document_uri;
    fastcgi_param  DOCUMENT_ROOT    $document_root;
    fastcgi_param  SERVER_PROTOCOL  $server_protocol;
    fastcgi_param  REQUEST_SCHEME   $scheme;
    fastcgi_param  HTTPS            $https                 if_not_empty;

    fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
    fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

    fastcgi_param  REMOTE_ADDR  $remote_addr;
    fastcgi_param  REMOTE_PORT  $remote_port;
    fastcgi_param  REMOTE_USER  $remote_user;
    fastcgi_param  SERVER_ADDR  $server_addr;
    fastcgi_param  SERVER_PORT  $server_port;
    fastcgi_param  SERVER_NAME  $server_name;

    # PHP only, required if PHP was built with --enable-force-cgi-redirect
    fastcgi_param  REDIRECT_STATUS  200;

    uwsgi_param  QUERY_STRING    $query_string;
    uwsgi_param  REQUEST_METHOD  $request_method;
    uwsgi_param  CONTENT_TYPE    $content_type;
    uwsgi_param  CONTENT_LENGTH  $content_length;

    uwsgi_param  REQUEST_URI      $request_uri;
    uwsgi_param  PATH_INFO        $document_uri;
    uwsgi_param  DOCUMENT_ROOT    $document_root;
    uwsgi_param  SERVER_PROTOCOL  $server_protocol;
    uwsgi_param  REQUEST_SCHEME   $scheme;
    uwsgi_param  HTTPS            $https             if_not_empty;

    uwsgi_param  REMOTE_ADDR  $remote_addr;
    uwsgi_param  REMOTE_PORT  $remote_port;
    uwsgi_param  SERVER_PORT  $server_port;
    uwsgi_param  SERVER_NAME  $server_name;

    ssl_dhparam          dh4096.pem;
    ssl_session_cache    shared:SSL:2m;
    ssl_session_timeout  1h;
    ssl_session_tickets  off;

    server {
        listen                   80       default_server;
        listen                   [::]:80  default_server;
        server_name              _;
        access_log               off;
        server_name_in_redirect  off;
        return                   444;
    }

    server {
        listen                   443       ssl;
        listen                   [::]:443  ssl;
        server_name              _;
        access_log               off;
        server_name_in_redirect  off;
        return                   444;
        ssl_certificate      adyxax.org.fullchain;
        ssl_certificate_key  adyxax.org.key;
    }

    include vhost.d/*.conf;
}
```

## Usage example

I do not call the role from a playbook, I prefer running the setup from an application's role that relies on nginx using a `meta/main.yaml` containing something like:

``` yaml
---
dependencies:
  - role: 'borg'
  - role: 'nginx'
  - role: 'postgresql'
```

Then from a tasks file:

``` yaml
- include_role:
    name: 'nginx'
    tasks_from: 'vhost'
  vars:
    vhost:
      name: 'www'
      path: 'roles/www.adyxax.org/files/nginx-vhost.conf'
```

I did not find an elegant way to pass a file path local to one role to another. Because of that, here I just specify the full vhost file path complete with the `roles/` prefix.

### Conclusion

I you have an elegant idea for passing the local file path from one role to another do not hesitate to ping me!
