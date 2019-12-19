# This website

This website is a static website build using [hugo](https://github.com/gohugoio/hugo). This article details how I installed hugo, how I initialised this website and how I manage it.

## Installing hugo

{{< highlight sh >}}
go get github.com/gohugoio/hugo
{{< / highlight >}}

This failed because the master branch in one of the dependencies was tainted, I fixed it with :
{{< highlight sh >}}
cd go/src/github.com/tdewolff/minify/
tig --all
git checkout v2.6.1
go get github.com/gohugoio/hugo
{{< / highlight >}}

This didn't build me the extended version of hugo that I need for the theme I chose, so I had to do :
{{< highlight sh >}}
cd ~/go/src/github.com/gohugoio/hugo/
go get --tags extended
go install --tags extended
{{< / highlight >}}

## Bootstraping this site

{{< highlight sh >}}
hugo new site www
cd www
git init
git submodule add https://github.com/alex-shpak/hugo-book themes/book
{{< / highlight >}}

## Live server for automatic rebuilding when writing

{{< highlight sh >}}
hugo server --bind 0.0.0.0 --minify
{{< / highlight >}}
