#!/usr/bin/env bash
set -euo pipefail

ret=0; buildah images adyxax/alpine &>/dev/null || ret=$?
if [[ "${ret}" != 0 ]]; then
	buildah rmi --all
	ALPINE_LATEST=$(curl --silent https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ |
		perl -lane '$latest = $1 if $_ =~ /^<a href="(alpine-minirootfs-\d+\.\d+\.\d+-x86_64\.tar\.gz)">/; END {print $latest}'
	)
	if [ ! -e "./${ALPINE_LATEST}" ]; then
		echo "Fetching ${ALPINE_LATEST}..."
		curl --silent "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/${ALPINE_LATEST}" \
			--output "./${ALPINE_LATEST}"
	fi

	ctr=$(buildah from scratch)
	buildah add "${ctr}" "${ALPINE_LATEST}" /
	buildah run "${ctr}" /bin/sh -c 'apk upgrade --no-cache'
	buildah run "${ctr}" /bin/sh -c 'apk add --no-cache pcre sqlite-libs'
	buildah commit "${ctr}" adyxax/alpine
	buildah rm "${ctr}"
fi

ret=0; buildah images adyxax/hugo &>/dev/null || ret=$?
if [[ "${ret}" != 0 ]]; then
	hugo=$(buildah from adyxax/alpine)
	buildah run "${hugo}" /bin/sh -c 'apk add --no-cache go git hugo make'
	buildah commit "${hugo}" adyxax/hugo
else
	hugo=$(buildah from adyxax/hugo)
fi

buildah run -v "${PWD}":/www "${hugo}" -- sh -c 'cd /www; make build'
buildah rm "${hugo}"

ret=0; buildah images adyxax/nginx &>/dev/null || ret=$?
if [[ "${ret}" != 0 ]]; then
	nginx=$(buildah from adyxax/alpine)
	buildah run "${nginx}" /bin/sh -c 'apk add --no-cache nginx'
	buildah commit "${nginx}" adyxax/nginx
else
	nginx=$(buildah from adyxax/nginx)
fi

(cd deploy && buildah copy "${nginx}" nginx.conf headers_secure.conf headers_static.conf /etc/nginx/)
buildah config \
	--author 'Julien Dessaux' \
	--cmd nginx \
	--port 80 \
	"${nginx}"
buildah copy "${nginx}" public /var/www/www.adyxax.org

buildah commit "${nginx}" adyxax/www
buildah rm "${nginx}"

ctr=$(buildah from scratch)
buildah copy "${ctr}" search/search /
buildah config \
	--author 'Julien Dessaux' \
	--cmd /search \
	--port 8080 \
	"${ctr}"
buildah commit "${ctr}" adyxax/www-search
buildah rm "${ctr}"
