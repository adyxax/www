.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
.ONESHELL:
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

##### Variables ################################################################
CACHEDIR := /tmp/hugo-cache-$(USER)
HOSTNAME := $(shell hostname -f)

##### Development ##############################################################
.PHONY: build
build: no-dirty ## make build
	@echo "----- Generating site -----"
	hugo --gc --minify --cleanDestinationDir -d public/ \
	     --cacheDir $(CACHEDIR) --buildFuture
	cp public/index.json search/
	cp public/search/index.html search/
	cd search
	CGO_ENABLED=0 go build -ldflags '-s -w -extldflags "-static"' ./search.go

.PHONY: clean
clean: ## make clean
	@echo "----- Cleaning old build -----"
	rm -f search/index.html search/index.json search/search
	rm -rf public

.PHONY: serve
serve: ## make serve		# hugo web server development mode
	hugo serve --disableFastRender --noHTTPCache \
	     --cacheDir $(CACHEDIR) --bind 0.0.0.0 --port 1313 \
	     -b http://$(HOSTNAME):1313/ --buildFuture --navigateToChanged

##### Operations ###############################################################
.PHONY: deploy
deploy: ## make deploy
	rsync -a --delete public/ www@www.adyxax.org:/srv/www/public/
	rsync search/search www@www.adyxax.org:/srv/www/
	ssh www@www.adyxax.org "systemctl --user restart www-search"

##### Quality ##################################################################
.PHONY: check
check: ## run all code checks
	(cd search && go mod verify && go vet ./...)

.PHONY: tidy
tidy: ## tidy up the code
	(cd search && go fmt ./... && go mod tidy -v)

##### Utils ####################################################################
.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

.PHONY: help
help:
	@grep -E '^[a-zA-Z\/_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' \
	| sort

.PHONY: no-dirty
no-dirty:
	git diff --exit-code
