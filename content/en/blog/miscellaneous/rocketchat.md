---
title: "RocketChat"
linkTitle: "RocketChat"
date: 2019-08-06
description: >
  RocketChat
---

Docker simple install :
{{< highlight sh >}}
docker run --name db -d mongo --smallfiles --replSet hurricane

docker exec -ti db mongo
> rs.initiate()

docker run -p 3000:3000 --name rocketchat --env ROOT_URL=http://hurricane --env MONGO_OPLOG_URL=mongodb://db:27017/local?replSet=hurricane  --link db -d rocket.chat
{{< /highlight >}}

