---
title: Implementing a search feature for my hugo static website
description: A golang webservice to complement hugo
date: 2021-09-19
tags:
- golang
- hugo
---

## Introduction

When I migrated my personal website from dokuwiki to hugo two years ago, the main feature I lost was a way to search the website content. I used [tags](/tags) to mimic a fraction of this power, but with more and more articles over the years I felt the pressure to finally do something.

Hugo can easily generate a json index of the website, and according to my google-fu hugo users use javascript solutions to implement search on top of this. I was not satisfied by the idea of having javascript download the whole website index and running searches locally, but I found no alternative. Since I love having a javascript free website I wanted to keep it that way if possible, so I designed an alternative.

This blog post retraces my steps in programming a custom search feature in golang and hosting it alongside my blog on my personal infrastructure.

## The design

Up until now the website was served from a simple nginx configuration. I plan to write a golang webservice, have nginx redirect the `/search` path to it and keep serving all the other paths statically. Having some experience from my work on my [trains webapp](https://git.adyxax.org/adyxax/trains) I had a pretty good idea how to write the http handler, I just needed to figure out three things :
- How to generate the JSON index with the information I need.
- How to make the search page integrate perfectly with the website.
- How to leverage the JSON index and which search algorithm to implement.

### The JSON index

There are two things to configure in order to get a JSON index from hugo. The first one is to activate JSON as an output format in `config.toml` :
```toml
[outputs]
home = ["HTML", "RSS", "JSON"]
```

The second is to create a `layouts/index.json` template of what the index will contain. Here is mine, if you decide to tweak it you will need to rework the search algorithm accordingly :
```html
{{- $.Scratch.Add "index" slice -}}
{{- range .Site.RegularPages -}}
    {{- $.Scratch.Add "index" (dict "title" .Title "description" .Params.description "tags"
    .Params.tags "content" .Plain "permalink" .Permalink) -}}
{{- end -}}
{{- $.Scratch.Get "index" | jsonify -}}
```

### How to maintain a coherent look

Since I am writing a golang webservice I can use its HTML templating library. It is handy because hugo uses the same library, but I cannot just reuse my hugo templates since they use hugo functions and api which would be a headache to mimic. One of the main pain points is to be able to reuse the css hugo generates, fingerprint and all.

In order to solve this I thought about my [custom hugo shortcodes]({{< ref "adding-custom-shortcode-age" >}}) and figured a way to use it to my advantage. I added a content section with a single page in `content/search/_index.md` :
```markdown
---
title: "Search"
menu:
  main:
    weight: 1
layout: single
---

What are you looking for ?
```

To render this page I wrote the corresponding layout in `layouts/search/single.html` :
```html
{{ define "main" }}

{{ .Content }}

{{ print "{{ template \"search\" . }}" }}

{{ end }}
```

And VOILÀ! When building the hugo website, it generates a page that contains a simple and valid html template that I can render :
```html
<!-- headers with css and everything exactly as on every page of the website,
     as well as the menu and its section highlighting) -->
<p>What are you looking for ?</p>
{{ template "search" . }}
<!-- the footer -->
```

The `search` template just need to be written accordingly, and the http templating library will do the rest.

### The golang webservice

The webservice lives in a folder of my hugo repository and can be found [here](https://git.adyxax.org/adyxax/www/tree/search). The website's makefile first builds the hugo website, then copies the HTML template and the json index in the search folder. It then builds the golang binary and embeds these.

When the webservice starts, it parses the JSON index and generates separate lists of unique words found in titles, descriptions, tags and page content. These lists each have a weight that factors in the results when the searched words are found in the list via a simple `string.Contains` match.

It is not very clever but because my website is small it produces pertinent results with this very simple algorithm. A friend pointed to me that Radix Trees are the efficient way to search if a word is part of a text and I plan to look into implementing that one day.

## Conclusion

I find that this search feature works well and looks even better! Being light and fast it fits perfectly with my philosophy for this website, and I find that managing a server side service is preferable to pushing the burden to the visitor's browser.

Future improvements I am considering (beside radix trees) are :
- allow to search for a phrase, right now words are split and handled similarly as if a OR was used.
- allow to request a word be present in the results (right now it is a OR).
- allow to match negatively against a word or pattern.
- permit a verbatim search to prevent substring matches.
- optionally select tags from a list, either positively or negatively.
- maybe factor pages' publishing date as a results sorting option.
