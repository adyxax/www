---
title: "How to run Syncthing from Termux and Tasker on Android"
date: "2026-03-19"
description: "Moving away from the app"
tags:
  - "Android"
  - "Syncthing"
  - "Termux"
---

## Introduction

I recently had my phone die on me and had to get a new one. One of the first
apps I install is [Syncthing](https://syncthing.net/), in order to restore my
photos and app data.

Syncthing on Android has had quite the history, and for a time it was the norm
to use Syncthing-Fork. A few months ago, this fork went through an ownership
change, and I stopped updating this app until things settled.

On a new device, I wanted an up to date setup I could trust long-term and
maintain myself. I found that the safest way for me to run Syncthing on Android
was to turn to [Termux](https://github.com/termux/termux-app).

## Termux

I have been using Termux for about a decade. It is a simple and reliable way to
get a Linux shell running on your phone. I only used it to SSH on servers and
run some tools while on the go up until now, but of course it is possible to run
server software on it.

Installing Termux is not difficult, but a few post installation steps need to be
performed. I personally download the APK from
[f-droid](https://f-droid.org/en/packages/com.termux/), without installing
f-droid itself.

When running Termux for the first time, I update it then setup the internal
phone's storage access with:

``` shell
apt update -qq && apt dist-upgrade -y
termux-setup-storage
```

It is important to go into the Termux app settings and allow Termux to run in
the background by disabling battery optimizations. Without that, it will get
killed periodically by Android.

I then install and initialize syncthing with:

``` shell
apt install syncthing -y
syncthing
```

This opens a web browser (or prints a URL you can open, depending on your
environment) with the usual syncthing configuration page. In the settings I
change the following for privacy:

- Disable anonymous usage reporting.
- Set a gui authentication user and password.
- Disable NAT traversal.
- Disable local discovery.
- Disable global discovery.
- Disable relaying.

I then proceed to add remote servers and folders.

## Tasker

Since I use syncthing to synchronize my photos with my NAS at home, one of the
main features of the Syncthing apps for me was to stop the background sync while
not connected to a WiFi network.

By combining [Tasker](https://tasker.joaoapps.com/) and
[Tmux:Tasker](https://github.com/termux/termux-tasker), I managed to get this
feature back and improved, since I can now also filter on which networks I allow
Syncthing to run.

If you left Syncthing running in Termux, now is the time to `C-c` to close it.
In Termux, edit `~/.termux/termux.properties` and uncomment the following so
that Tasker can execute commands:

``` properties
allow-external-apps = true
```

Go to Tasker's Android app permissions, and under `Additional permissions`
select `Run commands in Termux environment`. Restart Termux for the changes to
take effect.

Then I create the Termux:Tasker script directory as well as the start and stop
scripts:

``` shell
cat >~/.termux/tasker/start-syncthing.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
pgrep -x syncthing || syncthing serve --no-browser
EOF
cat >~/.termux/tasker/stop-syncthing.sh <<EOF
#!/data/data/com.termux/files/usr/bin/bash
pkill -x syncthing
EOF
chmod +x ~/.termux/tasker/*.sh
```

Then I open Tasker and create a profile for `State`, `Net`, `WiFi Connected`. I
set my WiFi SSID, then add a task named `Start Syncthing` and configure it with:

- Add `Action`, select `Plugin` then `Termux:Tasker`.
- Click `Configuration` then set `start-syncthing.sh` as the command then
  disable `wait for result`.
- Go back to the profile and long press the task. Select `Add Exit Task` and
  name it `Stop Syncthing`.
- Add `Action`, select `Plugin` then `Termux:Tasker`.
- Click `Configuration` then set `stop-syncthing.sh` as the command then disable
  `wait for result`.

All that remains to do is test by connecting and disconnecting the WiFi and run
`pgrep -x syncthing >/dev/null && echo running`.

## Conclusion

I am very happy with this setup, it works perfectly and provides me with a
robust and trustworthy way to run Syncthing again.
