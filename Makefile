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

build-local:
	bundle exec jekyll build --config _config.yml,_config_local.yml

change-images-assets-to-symlink:
	rm -rf ./_site/assets/images
	ln -sr ./assets/images ./_site/assets/images

remove-symlink:
	rm _site/assets/images

serve-local: # Run change-images-assets-to-symlink for faster reload time
	bundle exec jekyll serve --livereload --config _config.yml,_config_local.yml
