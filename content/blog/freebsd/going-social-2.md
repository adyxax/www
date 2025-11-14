---
title: Going Social take two
description: another ActivityPub server experiment
date: 2022-11-29
tags:
- FreeBSD
- jail
---

## Introduction

About a week after [setting up my fediverse personal instance]({{< ref "going-social.md" >}}), I grew frustrated with ktistec. Notifications do not work properly, there are no options to hide boost of a contact and some other minor things.

I did not give up right there, I first tried to see if I could maybe contribute and learn myself some crystal along the way. What made me give up is the good 15 minutes of compilation time for this app, on a rather powerful workstation that can compile the whole of firefox under thirty minutes! Call me old fashion but that is way too much for a simple web app.

## Something you need to know about fediverse instances hostnames

I discovered that once you used a hostname for an activity pub server, you will not be able to reuse it! social.adyxax.org will no longer be used on the fediverses! Federation relies on instances rsa keys: when first contacted, your instance advertised its public key and other instances learned it. When starting from scratch your new server will advertise a different key and get *SILENTLY IGNORED*!

These keys could theoretically be exported and reused in another software stack, but unless you can get the developers of both to collaborate closely to develop and then maintain something like this you will not get far because there are also users keys that work the same way.

A reminder if needed be to be very mindful of your backups!

The only viable way to migrate is to change your domain name and start from scratch on a brand new one. I took the opportunity to learn about webfinger and other `/well-known` subpaths to setup this new instance directly on adyxax.org instead of fedi.adyxax.org which I find cleaner.

## gotosocial

I went with [gotosocial](https://docs.gotosocial.org/en/latest/) though I am a little scared of the weight of the code repository. Once compiled and running, it is even lighter than ktistec (about 50M of ram) by not providing a web frontend. I like this idea of a backend only service, leaving the ui to the existing mastodon frontends. I found [tusky](https://f-droid.org/packages/com.keylesspalace.tusky/) to be its perfect companion.

Since the project releases a binary for FreeBSD, I chose to deploy in a FreeBSD jail. For other deployment methods, please refer to their great [official documentation](https://docs.gotosocial.org/en/latest/).

### Preparing the jail

There is nothing fancy needed, a basic jail without any package installed will work perfectly. Personally I deploy jails using the basic [handbook approach](https://docs.freebsd.org/en/books/handbook/jails/#jails-application) which I automated using ansible (I realise I never blogged about it, I will fix that in the future).

Here is my `/etc/jail.conf.d/fedi.conf`:
```cfg
fedi {
        host.hostname = "fedi";
        path = /jails/$name/root;
        ip4.addr = 127.0.1.3;
        ip6 = "new";
        ip6.addr = fc00::3;
        exec.clean;
        exec.prestart = "ifconfig lo1 alias ${ip4.addr}";
        exec.prestart += "ifconfig lo1 inet6 ${ip6.addr}";
        exec.prestart += "/sbin/pfctl -t jails -T add ${ip4.addr}";
        exec.prestart += "/sbin/pfctl -t jails -T add ${ip6.addr}";
        exec.poststop = "pfctl -a rdr/jail-$name -F nat";
        exec.poststop += "/sbin/pfctl -t jails -T del ${ip6.addr}";
        exec.poststop += "/sbin/pfctl -t jails -T del ${ip4.addr}";
        exec.poststop += "ifconfig lo1 inet6 ${ip6.addr} -alias";
        exec.poststop += "ifconfig lo1 inet ${ip4.addr} -alias";
        exec.start = "/usr/bin/su - fedi -c '/home/fedi/gotosocial --config-path /home/fedi/config.yaml server start' &";
        exec.stop = "pkill gotosocial ; sleep 1";
        mount.devfs;
}
```

For the first start, you will need to use the default start and stop actions:
```cfg
exec.start = "/bin/sh /etc/rc";
exec.stop = "/bin/sh /etc/rc.shutdown jail";
```

In the jail I created a dedicated user with:
```sh
adduser
Username: fedi
Full name: fedi
Uid (Leave empty for default):
Login group [fedi]:
Login group is fedi. Invite fedi into other groups? []:
Login class [default]:
Shell (sh csh tcsh git-shell bash rbash nologin) [sh]:
Home directory [/home/fedi]:
Home directory permissions (Leave empty for default):
Use password-based authentication? [yes]: no
Lock out the account after creation? [no]:
Username   : fedi
Password   : <disabled>
Full Name  : fedi
Uid        : 1002
Class      :
Groups     : fedi
Home       : /home/fedi
Home Mode  :
Shell      : /bin/sh
Locked     : no
```

Then I ran the following:
```sh
su - fedi
fetch https://github.com/superseriousbusiness/gotosocial/releases/download/v0.5.2/gotosocial_0.5.2_freebsd_amd64.tar.gz
tar xzf gotosocial-*.tar.gz
mv example/config.yaml .
rmdir example
vi config.yaml  # configure your instance
./gotosocial --config-path ./config.yaml admin account create --username adyxax --email prenom.nom@adyxax.org --password something_secret
./gotosocial --config-path ./config.yaml admin account confirm --username adyxax
./gotosocial --config-path ./config.yaml server start
```

### nginx reverse proxy

I use the following nginx configuration to proxy traffic from the host to the jail:
```cfg
server {
        listen  80;
        listen  [::]:80;
        server_name  fedi.adyxax.org;
        location / {
                return 308 https://$server_name$request_uri;
        }
}
server {
        listen  443       ssl;
        listen  [::]:443  ssl;
        server_name  fedi.adyxax.org;
        location / {
                proxy_pass  http://127.0.1.3:8080;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-For $remote_addr;
                proxy_set_header X-Forwarded-Proto $scheme;
                client_max_body_size 40M;
        }
        ssl_certificate      adyxax.org.fullchain;
        ssl_certificate_key  adyxax.org.key;
}
```

### adyxax.org redirections

Now comes the part about the `/.well-known` redirections that allow my instance to be hosted on fedi.adyxax.org while my user is known as being on adyxax.org. Pretty neat!

These mechanisms come from OpenID. A remote instance inquiring about my user will make http requests to https://adyxax.org/.well-known/webfinger?resource=acct:@adyxax@adyxax.org and get the aliasing to fedi.adyxax.org in response.

The gotosocial documentation only listed that redirections of `/.well-known/webfinger` and `/.well-known/nodeinfo` were necessary, but to successfully federate with a pleroma instance I needed other paths like `/.well-known/host-meta` so decided to proxy the whole `/.well-known` folder for now. I will see my logs in a few days and maybe restrict that a little.

The host my adyxax.org domain points to now has the following nginx configuration:
```cfg
server {
        listen     80;
        listen     [::]:80;
        server_name  adyxax.org;
        location /.well-known {
                return 308 https://fedi.adyxax.org$request_uri;
        }
        location / {
                return 308 https://www.adyxax.org$request_uri;
        }
}
server {
        listen     443 ssl;
        listen     [::]:443 ssl;
        server_name  adyxax.org;
        location /.well-known {
                return 308 https://fedi.adyxax.org$request_uri;
        }
        location / {
                return 308 https://www.adyxax.org$request_uri;
        }
        ssl_certificate      adyxax.org.fullchain;
        ssl_certificate_key  adyxax.org.key;
}
```

### Recompiling

When debugging my pleroma federation issues, I fetched the gotosocial repository and built a bleeding edge version. It worked easily but here I my notes anyway:
```sh
git clone https://github.com/superseriousbusiness/gotosocial
cd gotosocial
sed -e 's/go build/GOOS=freebsd GOARCH=amd64 CGO_ENABLED=0 go build/' -i scripts/build.sh
./scripts/build.sh
nix-channel --update
nix-env --upgrade
nix-env -i yarn
cd web/source
yarn install
cd -
./scripts/bundle.sh
```

To deploy:
```sh
rsync -r --exclude web/source gotosocial web root@lore.adyxax.org:/jails/fedi/root/home/fedi/
ssh root@lore.adyxax.org chown -R 1001 /jails/fedi/root/home/fedi/
```

Then restart the jail.

## Backups

Backups are configured with borg on my host `lore.adyxax.org` and stored on `yen.adyxax.org`. There are two jobs:
```yaml
- { name: gotosocial-data, path: "/jails/fedi/root/home/fedi/storage" }
- name: gotosocial-db
  path: "/tmp/gotosocial.db"
  pre_command: "echo \"VACUUM INTO '/tmp/gotosocial.db'\"|sqlite3 /jails/fedi/root/home/fedi/sqlite.db"
  post_command: "rm -f /tmp/gotosocial.db"
```

## Conclusion

So far it seems to work great, I will see in a few days but I am rather confident. You can reach me at [@adyxax@adyxax.org](https://fedi.adyxax.org/@adyxax) if you want, I would like to hear from you and really try this social experiment!
