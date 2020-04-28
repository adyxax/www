---
title: "Cleaning a docker host"
linkTitle: "Cleaning a docker host"
date: 2018-01-29
description: >
  How to retrieve storage space by cleaning a docker host
---

Be carefull that this will delete any stopped container and remove any locally unused image and tags :
{{< highlight sh >}}
docker system prune -f -a
{{< /highlight >}}
