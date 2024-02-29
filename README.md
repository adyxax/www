# www : My personal website

My name is Julien Dessaux, also known by my pseudonym Adyxax : welcome to my personal website!

These pages are an aggregation of various thoughts and tutorials I accumulated over my years of service as a system and network administrator and architect. Topics covered are open source, BSD and GNU/Linux system administration, and networking. It is a personal space that I try to fill up with my experience and knowledge of computer systems and network administration in the hope it serves others. You can learn more about me on this page.

I hope you feel welcome here, do not hesitate to leave a message at julien -DOT- dessaux -AT- adyxax -DOT- org. You can ask for a translation, some more details on a topic covered here, or just say hi or whatever ;-)

Have a good time!

## Contents

- [Dependencies](#dependencies)
- [Quick Start](#Quick-Start)
- [Hugo](#Hugo)
- [Search](#Search)
- [Kubernetes](#Kubernetes)

## Dependencies

go is required for the search feature. Only go version >= 1.22 on linux amd64 (Gentoo) is being regularly tested.

hugo is required in order to build the website html pages. Only hugo >= 0.111.3 is being regularly tested.

buildah is optionally required in order to build the container images with my deploy script.

## Quick Start

There is a makefile with everything you need, just type `make help` (or `gmake help` if running BSD).

## Hugo

Contrary to popular usage, I do not use a theme with hugo. I decided to simplify write my own in order to keep it light and simple. Here is a breakdown of each folder's contents:

- assets/: css files, which will be compiled into a single minified file.
- content/: markdown files
    - blog/: blog section of this website.
    - books/: a log of simple reviews of books I read.
    - docs/: wiki like section, where information is not sorted just chronologically like in the blog section.
    - search/: dummy section I need for the search feature.
- deploy/: container images building script.
- layouts/: html, json and rss templates. Also some useful hugo shortcodes.
- search: the go program that powers the search feature.
- static: favicon, blog images and schematics.

## Search

Hugo can easily generate a json index of the website, and according to my google-fu hugo users use javascript solutions to implement search on top of this. I was not satisfied by the idea of having javascript download the whole website index and running searches locally, but I found no alternative. Since I love having a javascript free website I wanted to keep it that way if possible, so I designed an alternative.

The search folders contains code for a go webservice that can handle search queries and serve results. It is fully integrated in the container images build process to maintain a coherent look with the website. For more details, see the related [blog article](https://www.adyxax.org/blog/2021/09/19/implementing-a-search-feature-for-my-hugo-static-website/).

## Kubernetes

I host this website on a k3s cluster. An example manifest can be found in the deploy folder.
