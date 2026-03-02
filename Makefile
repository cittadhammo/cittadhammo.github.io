.PHONY: help assets maps-html images images-uncompressed images-uncompressed-lossless images-compressed-lossy darkify-test darkify-test-thumbnails structure structure-check structure-sync-check clean sync-config build serve sync-agent-docs link-site-assets remove-site-asset-symlinks sync-download-assets

DARKIFY_TEST_INPUT ?= ./scripts/darkify-test/input
DARKIFY_TEST_OUTPUT ?= ./scripts/darkify-test/output
DARKIFY_THUMBS_OUTPUT ?= ./scripts/darkify-test/output-thumbnails
DARKIFY_CONFIG_FILE ?= ./_config.yml
DARKIFY_THUMBS_CONFIG_FILE ?= ./scripts/darkify-test/levels.yml
STRUCTURE_CONTENT_DIR ?= ./vault/content
STRUCTURE_CONFIG_FILE ?= ./_config.yml
STRUCTURE_AREAS_FILE ?= ./vault/data/areas.yml

# Run the search and mapping script
assets:
	bash ./scripts/generate_assets.sh

# Regenerate map HTML only (no tiles or thumbnails)
maps-html:
	MAPS_HTML_ONLY=true bash ./scripts/generate_assets.sh

# Generate PDF and PNG by running Python script in the vault directory (default: lossy compression)
images:
	cd vault && python3 ./scripts/generate_pdf_png.py --compression lossy

images-uncompressed:
	cd vault && python3 ./scripts/generate_pdf_png.py

images-uncompressed-lossless:
	cd vault && python3 ./scripts/generate_pdf_png.py --compression lossless

images-compressed-lossy:
	cd vault && python3 ./scripts/generate_pdf_png.py --compression lossy

# Compare all darkify methods on images in scripts/darkify-test/input
darkify-test:
	DARKIFY_CONFIG_FILE="$(DARKIFY_CONFIG_FILE)" \
	bash ./scripts/darkify-test/run.sh "$(DARKIFY_TEST_INPUT)" "$(DARKIFY_TEST_OUTPUT)"

# Generate original + small/medium/large thumbnail darkify test outputs
darkify-test-thumbnails:
	DARKIFY_CONFIG_FILE="$(DARKIFY_CONFIG_FILE)" \
	DARKIFY_TEST_THUMBS_CONFIG_FILE="$(DARKIFY_THUMBS_CONFIG_FILE)" \
	DARKIFY_INVERT_LEVEL_DEFAULT="$(DARKIFY_INVERT_LEVEL_DEFAULT)" \
	DARKIFY_INVERT_LEVEL_SMALL="$(DARKIFY_INVERT_LEVEL_SMALL)" \
	DARKIFY_INVERT_LEVEL_MEDIUM="$(DARKIFY_INVERT_LEVEL_MEDIUM)" \
	DARKIFY_INVERT_LEVEL_LARGE="$(DARKIFY_INVERT_LEVEL_LARGE)" \
	bash ./scripts/darkify-test/run-thumbnails.sh "$(DARKIFY_TEST_INPUT)" "$(DARKIFY_THUMBS_OUTPUT)"

# Sync collections/defaults/areas with folders under vault/content/_*
structure:
	bash ./scripts/sync_structure.sh "$(STRUCTURE_CONTENT_DIR)" "$(STRUCTURE_CONFIG_FILE)" "$(STRUCTURE_AREAS_FILE)"

# Check collections/defaults/areas are already in sync (no file changes)
structure-check:
	bash ./scripts/check_structure_sync.sh "$(STRUCTURE_CONTENT_DIR)" "$(STRUCTURE_CONFIG_FILE)" "$(STRUCTURE_AREAS_FILE)"

# Sync then verify no remaining drift
structure-sync-check: structure structure-check

clean:
	rm -rf assets/images/*
	rm -rf assets/pdfs/*
	rm -rf assets/svgs/*
	rm -rf maps/*

# Updates _config_local.yml's exclude list with _config.yml's exclude list, and adds local asset symlink paths
sync-config:
	yq -i '.exclude = (load("_config.yml").exclude + ["assets/images","assets/pdfs","assets/svgs"])' _config_local.yml

link-site-assets:
	# You might need to build the site first to get the assets folder in _site
	mkdir -p ./_site/assets
	rm -rf ./_site/assets/images ./_site/assets/pdfs ./_site/assets/svgs
	ln -sr ./assets/images ./_site/assets/images
	ln -sr ./assets/pdfs ./_site/assets/pdfs
	ln -sr ./assets/svgs ./_site/assets/svgs

remove-site-asset-symlinks:
	rm -f ./_site/assets/images ./_site/assets/pdfs ./_site/assets/svgs

sync-download-assets:
	mkdir -p ./assets/pdfs ./assets/svgs
	rm -rf ./assets/pdfs/* ./assets/svgs/*
	cp -a ./vault/assets/pdfs/. ./assets/pdfs/
	cp -a ./vault/assets/svgs/. ./assets/svgs/

build: # careful with the keep file in config_local
	$(MAKE) sync-download-assets
	bundle exec jekyll build --config _config.yml,_config_local.yml
	$(MAKE) link-site-assets

change-images-assets-to-symlink:
	$(MAKE) link-site-assets

remove-symlink:
	$(MAKE) remove-site-asset-symlinks

serve: # keep_files in _config_local.yml preserves asset symlinks during serve
	$(MAKE) sync-download-assets
	$(MAKE) link-site-assets
	bundle exec jekyll serve --livereload --config _config.yml,_config_local.yml

sync-agent-docs:
	cp AGENTS.md GEMINI.md

help:
	@echo "DhammaCharts Make Targets"
	@echo ""
	@echo "Commands:"
	@echo "  make assets                    Generate/copy image assets + map tiles/viewers"
	@echo "  make maps-html                 Regenerate map HTML only (no tiles/thumbnails)"
	@echo "  make images                    Generate PDF/PNG assets (lossy)"
	@echo "  make images-uncompressed       Generate PDF/PNG assets (default script mode)"
	@echo "  make images-uncompressed-lossless  Generate PDF/PNG assets (lossless)"
	@echo "  make images-compressed-lossy   Generate PDF/PNG assets (lossy)"
	@echo "  make build                     Build Jekyll site with _config.yml + _config_local.yml"
	@echo "  make serve                     Serve site locally with livereload"
	@echo "  make sync-download-assets      Copy vault/assets/{pdfs,svgs} into assets/{pdfs,svgs}"
	@echo "  make link-site-assets          Symlink images/pdfs/svgs into _site/assets"
	@echo "  make remove-site-asset-symlinks  Remove asset symlinks from _site/assets"
	@echo "  make clean                     Remove generated assets/images and maps"
	@echo "  make sync-config               Sync _config_local.yml exclude list"
	@echo "  make darkify-test              Run method comparison darkify test harness"
	@echo "  make darkify-test-thumbnails   Run original + thumbnail darkify test harness"
	@echo "  make structure                 Sync all collection/folder/category/page refs into _config.yml and areas.yml"
	@echo "  make structure-check           Check if _config.yml and areas.yml are in sync (no changes)"
	@echo "  make structure-sync-check      Run sync then verify consistency"
	@echo "  make sync-agent-docs           Copy AGENTS.md to GEMINI.md"
	@echo ""
	@echo "Variables:"
	@echo "  DARKIFY_TEST_INPUT             Input dir for darkify tests"
	@echo "                                 Default: $(DARKIFY_TEST_INPUT)"
	@echo "  DARKIFY_TEST_OUTPUT            Output dir for make darkify-test"
	@echo "                                 Default: $(DARKIFY_TEST_OUTPUT)"
	@echo "  DARKIFY_THUMBS_OUTPUT          Output dir for make darkify-test-thumbnails"
	@echo "                                 Default: $(DARKIFY_THUMBS_OUTPUT)"
	@echo "  DARKIFY_CONFIG_FILE            Config file used for darkify defaults"
	@echo "                                 Default: $(DARKIFY_CONFIG_FILE)"
	@echo "  DARKIFY_THUMBS_CONFIG_FILE     Local thumbnail test level config (editable per run)"
	@echo "                                 Default: $(DARKIFY_THUMBS_CONFIG_FILE)"
	@echo "  DARKIFY_INVERT_LEVEL_DEFAULT   Level for original-dark in thumbnail test (e.g. 5%,95%)"
	@echo "                                 Default: env > $(DARKIFY_THUMBS_CONFIG_FILE) > $(DARKIFY_CONFIG_FILE) > 5%,95%"
	@echo "  DARKIFY_INVERT_LEVEL_SMALL     Level for small-dark thumbnail (e.g. 2%,82%)"
	@echo "                                 Default: env > $(DARKIFY_THUMBS_CONFIG_FILE) > $(DARKIFY_CONFIG_FILE) > 2%,82%"
	@echo "  DARKIFY_INVERT_LEVEL_MEDIUM    Level for medium-dark thumbnail (e.g. 3%,88%)"
	@echo "                                 Default: env > $(DARKIFY_THUMBS_CONFIG_FILE) > $(DARKIFY_CONFIG_FILE) > 3%,88%"
	@echo "  DARKIFY_INVERT_LEVEL_LARGE     Level for large-dark thumbnail (e.g. 4%,92%)"
	@echo "                                 Default: env > $(DARKIFY_THUMBS_CONFIG_FILE) > $(DARKIFY_CONFIG_FILE) > 4%,92%"
	@echo "  STRUCTURE_CONTENT_DIR          Source content root to scan for _collection dirs"
	@echo "                                 Default: $(STRUCTURE_CONTENT_DIR)"
	@echo "  STRUCTURE_CONFIG_FILE          _config.yml file to update"
	@echo "                                 Default: $(STRUCTURE_CONFIG_FILE)"
	@echo "  STRUCTURE_AREAS_FILE           areas.yml file to update"
	@echo "                                 Default: $(STRUCTURE_AREAS_FILE)"
	@echo ""
	@echo "Example:"
	@echo "  make darkify-test-thumbnails DARKIFY_INVERT_LEVEL_SMALL='1%,78%' DARKIFY_INVERT_LEVEL_MEDIUM='2%,85%' DARKIFY_INVERT_LEVEL_LARGE='3%,90%'"
