---
title: Custom hugo markdown shortcode
date: 2021-03-22
description: An example of custom hugo shortcode to calculate automatically something
tags:
  - hugo
---

## Introduction

On the [about-me]({{< ref "about-me" >}}) page I had hardcoded my age. I wanted a way to calculate it automatically when building the site, here is how to do this.

## Adding the shortcode

Added a custom markdown shortcode in hugo in as simple as creating a `layouts/shortcodes/` directory. Each html file created inside will define a shortcode from the filename. In my example I want to calculate my age so I named the shortcode `age.html` and added the following simple template code :

```html
{{ div (sub now.Unix 493473600 ) 31556926 }}
```

The first number is the timestamp of my birthday, the second represents how many seconds there are in a year.

## Using the shortcode

With this `layouts/shortcodes/age.html` file I can just add the following in a page to add my age :

```html
{{< print "{{% age %}}" >}}
```

And if you are wondering how I am able to display a shortcode code inside this page without having it render, it is because I defined another shortcode that does exactly like this :
```html
{{< print "{{ index .Params 0 }}" >}}
```

You can find these examples [here](https://git.adyxax.org/adyxax/www/tree/layouts/shortcodes)! Hugo really is a powerful static website generator, it is amazing.

## References

  * https://gohugo.io/content-management/shortcodes/
  * https://github.com/gohugoio/hugo/issues/7561
