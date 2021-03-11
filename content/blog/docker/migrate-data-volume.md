---
title: "Migrate a data volume"
date: 2018-01-30
description: How to migrate a data volume between two hosts
tags:
  - docker
---

## The command

Here is how to migrate a data volume between two of your hosts. A rsync of the proper `/var/lib/docker/volumes` subfolder would work just as well, but here is a fun way to do it with docker and pipes :
{{< highlight sh >}}
export VOLUME=tiddlywiki
export DEST=10.1.0.242
docker run --rm -v $VOLUME:/from alpine ash -c "cd /from ; tar -cpf - . " \
| ssh $DEST "docker run --rm -i -v $VOLUME:/to alpine ash -c 'cd /to ; tar -xfp - ' "
{{< /highlight >}}
