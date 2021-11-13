#!/usr/bin/env bash
set -eu

(cd .. && make clean build)

ret=0; output=$(buildah images adyxax/alpine &>/dev/null) || ret=$?
if [ $ret != 0 ]; then
	ALPINE_LATEST=$(curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ |
		perl -lane '$latest = $1 if $_ =~ /^<a href="(alpine-minirootfs-\d+\.\d+\.\d+-x86_64\.tar\.gz)">/; END {print $latest}'
	)
	if [ ! -e "./${ALPINE_LATEST}" ]; then
		echo "Fetching ${ALPINE_LATEST}..."
		curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/${ALPINE_LATEST} \
			--output ./${ALPINE_LATEST}
	fi

	ctr=$(buildah from scratch)
	buildah add $ctr ${ALPINE_LATEST} /
	buildah run $ctr /bin/sh -c 'apk add --no-cache pcre sqlite-libs'
	buildah commit $ctr adyxax/alpine
else
	ctr=$(buildah from adyxax/alpine)
	#buildah run $ctr /bin/sh -c 'apk upgrade --no-cache'
fi

ret=0; buildah images adyxax/nginx &>/dev/null || ret=$?
if [ $ret != 0 ]; then
	nginx=$(buildah from adyxax/alpine)
	buildah run $nginx /bin/sh -c 'apk add --no-cache nginx'
	buildah commit $nginx adyxax/nginx
else
	nginx=$(buildah from adyxax/nginx)
	#buildah run $nginx /bin/sh -c 'apk upgrade --no-cache'
fi

buildah copy $nginx nginx.conf headers_secure.conf headers_static.conf /etc/nginx/
buildah config \
	--author 'Julien Dessaux' \
	--cmd nginx \
	--port 80 \
	$nginx
buildah copy $nginx ../public /var/www/www.adyxax.org

buildah commit $nginx adyxax/www
buildah rm $nginx

ctr=$(buildah from scratch)
buildah copy $ctr ../search/search /
buildah config \
	--author 'Julien Dessaux' \
	--cmd /search \
	--port 8080 \
	$ctr
buildah commit $ctr adyxax/www-search
buildah rm $ctr
