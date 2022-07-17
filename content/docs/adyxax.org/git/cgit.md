---
title: "cgit and nginx"
description: Installation notes of cgit
---

## Introduction

This article details how I installed and configured cgit on FreeBSD to serve as the web frontend of my gitolite repositories.

## Installation

cgit can be bootstrapped with the following :
```yaml
pkg install cgit fcgiwrap
```

## Configuration

Here is my `/usr/local/etc/cgitrc-adyxax` file:
```cfg
about-filter=/usr/local/lib/cgit/filters/about-formatting.sh
clone-url=https://$HTTP_HOST/$CGIT_REPO_URL
enable-commit-graph=1
enable-follow-links=1
enable-git-config=1
enable-log-filecount=1
enable-log-linecount=1
enable-subject-links=1
mimetype.gif=image/gif
mimetype.html=text/html
mimetype.jpg=image/jpeg
mimetype.jpeg=image/jpeg
mimetype.pdf=application/pdf
mimetype.png=image/png
mimetype.svg=image/svg+xml
noplainemail=1
readme=:README.md
remove-suffix=1
snapshots=tar.gz tar.bz2 zip
root-desc=All public git repositories by Adyxax
#root-readme=/var/www/htdocs/about.html
root-title=Adyxax's git repositories
virtual-root=/
scan-path=/home/git/repositories
```

## fcgiwrap

fcgiwrap is a necessary interface for nginx to call cgit. It is entirely configured from `/etc/rc.conf`, you just need to add:
```cfg
fcgiwrap_enable="YES"
fcgiwrap_profiles="git"
fcgiwrap_git_socket="unix:/var/run/fcgiwrap/git.socket"
fcgiwrap_git_user="git"
fcgiwrap_git_group="git"
fcgiwrap_git_socket_owner="www"
fcgiwrap_git_socket_group="www"
```

This ensures the cgit processes run as the `git` user, while nginx running as the `www` user can connect to it.

## nginx

I presume nginx is already setup, here is the snippet of configuration needed to serve cgit with fcgiwrap:
```cfg
server {
        listen     80;
        listen     [::]:80;
        server_name  git.adyxax.org;
        location / {
                return 308 https://$server_name$request_uri;
        }
}
server {
        listen     443 ssl;
        listen     [::]:443 ssl;
        server_name  git.adyxax.org;
        location /adyxax {
                try_files $uri @cgit-adyxax;
        }
        location @cgit-adyxax {
                include fastcgi_params;
                fastcgi_param CGIT_CONFIG /usr/local/etc/cgitrc-adyxax;
                fastcgi_param SCRIPT_FILENAME /usr/local/www/cgit/cgit.cgi;
                fastcgi_param PATH_INFO $uri;
                fastcgi_param QUERY_STRING $args;
                fastcgi_param HTTP_HOST $server_name;
                fastcgi_pass unix:/var/run/fcgiwrap/git.socket;
        }

        ssl_certificate /usr/local/etc/adyxax.org.fullchain;
        ssl_certificate_key /usr/local/etc/adyxax.org.key;
}
```
