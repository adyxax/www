---
title: "OpenStreetMap overlay example"
date: 2020-05-19
description: An example of how to query things visually on OpenStreetMap
tags:
  - toolbox
---

## The problem

OpenStreetMap is a great resource and there is a lot more information stored there than you can easily see.

## The solution

Go to http://overpass-turbo.eu/ and enter a filter script similar to the following :
{{< highlight html >}}
<osm-script>
  <query type="node">
    <has-kv k="amenity" v="recycling"/>
    <bbox-query {{bbox}}/>
  </query>
  <!-- print results -->
  <print mode="body"/>
</osm-script>
{{< /highlight >}}

This example will highlight the recycling points near a target location. From there you can build almost any filter you can think of!
