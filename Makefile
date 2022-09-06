CACHEDIR=/tmp/hugo-cache-$(USER)
DESTDIR=public/
HOSTNAME=$(shell hostname)
REVISION=$(shell git rev-parse HEAD)

.PHONY: build
build: ## make build  # builds an optimized version of the website in $(DESTDIR)
	@echo "----- Generating site -----"
	hugo --gc --minify --cleanDestinationDir -d $(DESTDIR) --cacheDir $(CACHEDIR)
	cp public/index.json search/
	cp public/search/index.html search/
	(cd search && CGO_ENABLED=0 go build -ldflags '-s -w -extldflags "-static"' ./search.go)

.PHONY: buildah
buildah: ## make buildah  # builds the container images
	deploy/build-image.sh

.PHONY: push
push: ## make push  # push the built images to quay.io
	buildah push adyxax/www quay.io/adyxax/www:$(REVISION)
	buildah push adyxax/www-search quay.io/adyxax/www-search:$(REVISION)

.PHONY: clean
clean: ## make clean  # removed all $(DESTDIR) contents
	@echo "----- Cleaning old build -----"
	rm -f search/index.html search/index.json search/search
	rm -rf $(DESTDIR)

.PHONY: serve
serve: ## make serve  # hugo web server development mode
	hugo serve --disableFastRender --noHTTPCache --cacheDir $(CACHEDIR) --bind 0.0.0.0 --port 1313 -b http://$(HOSTNAME):1313/

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
