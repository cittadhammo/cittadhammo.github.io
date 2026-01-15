.PHONY: assets

# Run Jekyll local server with livereload and local config
serve:
	jekyll serve --livereload --config _config.yml,_config_local.yml

# Run the search and mapping script
assets:
	bash ./scripts/generate_assets.sh

# Generate PDF and PNG by running Python script in the vault directory
images:
	cd vault && python3 ./scripts/generate_pdf_png2.py

clean:
	rm -rf assets/images/*
	rm -rf maps/*

serve-local:
	bundle exec jekyll serve --livereload --config _config.yml,_config_local.yml
