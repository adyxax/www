---
title: Container images
description: How container images are built, where they are stored and how they are deployed
tags:
- UpdateNeeded
---

## Building

There are two container images to serve a fully functional website:
- One for the hugo static website, running nginx and serving this site's static files
- One for the search web service written in go

These are both built with `buildah` using [the same script](https://git.adyxax.org/adyxax/ev-scripts/tree/www/build-images.sh).

Images are based on the latest alpine linux distribution available when building.

## Registry

The images are pushed to https://quay.io/.

## Continuous deployment

The build and deployment of the website is handled by `eventline` with the following jobs called from git hooks by `gitolite` when I `git push`:
- [www-build](https://git.adyxax.org/adyxax/ev-scripts/tree/www/www-build.yaml)
- [www-deploy](https://git.adyxax.org/adyxax/ev-scripts/tree/www/www-deploy.yaml)
