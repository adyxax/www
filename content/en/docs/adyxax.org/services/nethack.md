---
title: "nethack"
linkTitle: "nethack"
weight: 1
description: >
  nethack
---

## dgamelaunch

TODO

{{< highlight sh >}}
groupadd -r games
useradd -r -g games nethack
git clone 
{{< /highlight >}}

## nethack

TODO

{{< highlight sh >}}
{{< /highlight >}}

## scores script

TODO

{{< highlight sh >}}
{{< /highlight >}}

## copying shared libraries

{{< highlight sh >}}
cd /opt/nethack
for i in `ls bin`; do for l in `ldd bin/$i | tail -n +1 | cut -d'>' -f2 | awk '{print $1}'`; do if [ -f $l ]; then echo $l; cp $l lib64/; fi; done; done
for l in `ldd dgamelaunch | tail -n +1 | cut -d'>' -f2 | awk '{print $1}'`; do if [ -f $l ]; then echo $l; cp $l lib64/; fi; done
for l in `ldd nethack-3.7.0-r1/games/nethack | tail -n +1 | cut -d'>' -f2 | awk '{print $1}'`; do if [ -f $l ]; then echo $l; cp $l lib64/; fi; done
{{< /highlight >}}

## making device nodes

TODO! For now I mount all of /dev in the chroot :
{{< highlight sh >}}
#mknod -m 666 dev/ptmx c 5 2
mount -R /dev /opt/nethack/dev
{{< /highlight >}}

## debugging

{{< highlight sh >}}
gdb chroot
run --userspec=nethack:games /opt/nethack/ /dgamelaunch
{{< /highlight >}}

