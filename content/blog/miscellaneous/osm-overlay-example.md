---
title: "OpenStreetMap overlay example"
linkTitle: "OpenStreetMap overlay example"
date: 2020-05-19
description: >
  An example of how to query things visually on OpenStreetMap
---

http://overpass-turbo.eu/
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
