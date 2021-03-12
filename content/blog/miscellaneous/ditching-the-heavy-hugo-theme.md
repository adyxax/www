---
title: "Ditching the heavy hugo theme"
date: 2021-03-12
description: I needed to trim the fat from this blog you are reading
tags:
  - hugo
---

## Introduction

I felt a need for minimalism and was really uneasy at the thought of 11 requests totalling about 750KB of minified files just to display a home page without any images, all that because of the docsy theme I went with when I [switched to hugo]({{< relref "/blog/miscellaneous/switching-to-hugo" >}}) two years ago.

I am not complaining about the theme which served me well when I needed to switch and was so focused on manually importing 10 years worth of wiki articles, but this uneasiness prevented me from updating this blog as often as I wanted. I was a bit ashamed about how heavy it was.

## Learning CSS and hugo templating

Yeah, that's how it went for about a week's worth of time taken here and there : plain old learning and experimenting! I learned myself some css and basic hugo templating to rebuild this website's design from the ground up and squeeze down to a home page fetching only three requests weighing a little less than 5KB total. One could easily argue that the visual result is a little more austere but I like it.

I had severe misconceptions dating from about 10-15 years ago when I did some html and css manually for the first time. Even though I will never consider myself a web developer I am glad I pushed though these misconceptions and rediscovered these technologies with a fresh eye. Css really is not that hard nowadays, there is no longer a need for weird html tricks to ensure compatibility everywhere... the browser wars with internet explorer are far far behind us and that is a good thing.

I hesitated with several lightweight css frameworks and tried some, none left me satisfied. These certainly have their place when working in teams on big projects but they all left me puzzled. I finally went with the idea of doing it by hand with just a few classes here and there, almost everything simply attached to html tags which by the way are so much more expressive than I expected! When reading the framework documentations there were either layers of divs everywhere or dozens of classes on every element, but it is all unnecessary to get a working website. There are tags like header, footer, main, article, aside etc that have real meaning, no need for div div div div div or class="this that also-that"!

## Afterthoughts

My pre-requisites for this blog were :
  - a decent look on mobile, similar than on desktop
  - rss feeds
  - very light
  - link pagination

I added tags to all articles since I lost the search feature, but it was worthwhile to get rid of all the javascript on the website. I might work something out later to get a search feature, but it is not a heavy price to achieve this degree of minimalism.

You can check the repository [here](https://git.adyxax.org/adyxax/www), so light, so simple... I love it!
