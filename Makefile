.POSIX:
DESTDIR=public

.PHONY: build
build: ## make build  # builds an optimized version of the website in $(DESTDIR)
	@echo "? Generating site"
	hugo --gc --minify --cleanDestinationDir -d $(DESTDIR)


.PHONY: clean
clean: ## make clean  # removed all $(DESTDIR) contents
	@echo "? Cleaning old build"
	cd $(DESTDIR) && rm -rf *

.PHONY: serve
serve: ## make serve  # hugo web server development mode
	hugo serve --disableFastRender --noHTTPCache

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
