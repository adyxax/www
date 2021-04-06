---
title: "Exploring France's train network open data api"
date: 2021-04-06
description: I wrote a small web app to display train timetables
tags:
  - golang
---

## Introduction

I am quite fond of the open data initiatives in France and across Europe. When my partner expressed frustration at the official website and mobile applications full of ads and slow to query I decided to see what I could do to help.

## An extensive API

Let me tell you the API is quite extensive, you can query absolutely anything! Just have a look at the [documentation](http://doc.navitia.io/) : time tables, realtime departure information, journey planning... I did not expect something so complete!

It is free to use for up to 5000 API calls per day, which is really generous considering the pagination features allow you to get up to one thousand results per query for example when listing all of France's train stops.

## A small golang contribution

I wrote https://git.adyxax.org/adyxax/trains, which you can see live at https://trains.adyxax.org/. It is just a simple timetable for now but a lifechanging thing for my partner : no more frustration!

I also used this opportunity to polish my golang experience, it was my first time writing a web server with this language. I have several feature ideas like perturbation alerting or a small front to select and browse other stations than the one and only configured when the web app starts... but it might just be enough for our use case as it is. I will take a few days and think it over.
