#!/usr/bin/env bash
# shellcheck disable=SC3010,SC3040,SC3043
set -euCo pipefail
shopt -s globstar nullglob

cache_dir="/tmp/hugo-cache-$USER"
destination="$PWD/public"

assert_no_dirty() {
    git diff --exit-code || fatal "Error: dirty repository"
}

fatal() {
    printf '%b%s%b\n' "$RED" "$1" "$RESET" >&2
    exit 1
}

main_build() {
    hugo --gc --minify --cleanDestinationDir -d "$destination" \
         --cacheDir "$cache_dir" --buildFuture
    cp "$destination/index.json" search/
    cp "$destination/search/index.html" search/
    (cd search; CGO_ENABLED=0 go build -ldflags '-s -w -extldflags "-static"' ./search.go)
}

main_check() {
    shellcheck -s bash -- make.sh
    (cd search && go mod verify && go vet ./...)
}

main_clean() {
    rm -f search/index.html search/index.json search/search
    rm -rf "$destination"
}

main_deploy() {
    if [ "${fail_if_dirty:-true}" != false ]; then
        assert_no_dirty
    fi
    umask 077
    local SSHOPTS=()
    if [ -n "${SSH_PRIVATE_KEY:-}" ]; then
        # CI relies on this
        private_key="$PWD/private_key"
        cleanup() {
            rm -f "$private_key"
        }
        trap cleanup EXIT
        printf '%s' "$SSH_PRIVATE_KEY" | base64 -d > "$private_key"
        SSHOPTS=("-i" "$private_key" "-o" "StrictHostKeyChecking=accept-new")
    fi
    rsync -a --delete -e "ssh ${SSHOPTS[*]}" "$destination/" www@www.adyxax.org:/srv/www/public/
    rsync -e "ssh ${SSHOPTS[*]}" search/search www@www.adyxax.org:/srv/www/
    ssh "${SSHOPTS[@]}" www@www.adyxax.org "chmod +x search; systemctl --user restart www-search"
}

main_serve() {
    hugo serve --disableFastRender --noHTTPCache \
         --cacheDir "$cache_dir" --bind 0.0.0.0 --port 1313 \
         -b "http://$HOSTNAME:1313/" --buildFuture --navigateToChanged
}

main_tidy() {
    (cd search && go fmt ./... && go mod tidy -v)
    if [ "${fail_if_dirty:-false}" != false ]; then
        assert_no_dirty
    fi
}

main_update() {
    (cd search && go get -t -u ./... && go mod tidy)
}

usage() {
    if [[ -n "${1:-}" ]]; then
        printf '%b%s%b\n' "$RED" "$1" "$RESET" >&2
    fi
    echo "Usage:" >&2
    echo "    $0  build                          # build the website" >&2
    echo "    $0  check                          # run static checks" >&2
    echo "    $0  clean                          # clean build artifacts" >&2
    echo "    $0  deploy [--fail-if-dirty=true]  # deploy the website" >&2
    echo "    $0  update                         # update dependencies" >&2
    echo "    $0  serve                          #run a development web server" >&2
    echo "    $0  tidy [--fail-if-dirty=false]   # tidy up the code" >&2
    echo "Global options:" >&2
    echo "    -h, --help     # show this help message" >&2
    echo "    --no-colors    # disable colored output" >&2
    echo "    -v, --verbose  # verbose mode via set -x" >&2
    echo "Action specific options:" >&2
    echo "    --fail-if-dirty=<bool>  # exit 1 if the repository is dirty" >&2
    exit 1
}

PARSED=$(getopt -o hnv \
                -l fail-if-dirty:,help,no-colors,verbose \
                --name "$0" -- "$@") || exit 2
eval set -- "$PARSED"

RED='\033[0;31m'
RESET='\033[0m'

while true; do
    case "$1" in
        --fail-if-dirty) fail_if_dirty="$2"; shift 2 ;;
        -h|--help) usage ;;
        -n|--no-colors)
            RED=''
            RESET=''
            shift ;;
        -v|--verbose) verbose=1; shift ;;
        --) shift; break ;;
        *) break ;;
    esac
done

if [[ -z "${*}" ]]; then
    usage 'ERROR: missing action to run'
fi

if [[ -n "${verbose:-}" ]]; then set -x; fi
for action in "${@}"; do
    case "$action" in
        build) main_build ;;
        check) main_check ;;
        clean) main_clean ;;
        deploy) main_deploy ;;
        update) main_update ;;
        serve) main_serve ;;
        tidy) main_tidy ;;
        *) usage "ERROR: unknown action $action" ;;
    esac
done
