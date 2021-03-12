---
title: "RocketChat"
date: 2019-08-06
description: How to quickly setup a RocketChat container with docker
tags:
  - docker
  - toolbox
---

## The problem

I needed to test some scripts that interact with a rocketchat instance at work. The documentation was lacking especially the mongo initiate part so here is how I did it.

## The commands

Docker simple install :
{{< highlight sh >}}
docker run --name db -d mongo --smallfiles --replSet hurricane

docker exec -ti db mongo
> rs.initiate()

docker run -p 3000:3000 --name rocketchat --env ROOT_URL=http://hurricane --env MONGO_OPLOG_URL=mongodb://db:27017/local?replSet=hurricane  --link db -d rocket.chat
{{< /highlight >}}
