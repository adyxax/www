CACHEDIR=/tmp/hugo-cache-$(USER)
DESTDIR=public/
HOSTNAME=$(shell hostname)

.PHONY: build
build: ## make build  # builds an optimized version of the website in $(DESTDIR)
	@echo "----- Generating site -----"
	hugo --gc --minify --cleanDestinationDir -d $(DESTDIR) --cacheDir $(CACHEDIR)
	cp public/index.json search/
	cp public/search/index.html search/
	(cd search && CGO_ENABLED=0 go build -ldflags '-s -w -extldflags "-static"' ./search.go)

.PHONY: clean
clean: ## make clean  # removed all $(DESTDIR) contents
	@echo "----- Cleaning old build -----"
	rm -f search/index.html search/index.json search/search
	cd $(DESTDIR) && rm -rf *

.PHONY: serve
serve: ## make serve  # hugo web server development mode
	hugo serve --disableFastRender --noHTTPCache --cacheDir $(CACHEDIR) --bind 0.0.0.0 --port 1313 -b http://$(HOSTNAME):1313/

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
