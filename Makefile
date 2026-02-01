.PHONY: assets

# Run the search and mapping script
assets:
	bash ./scripts/generate_assets.sh

# Generate PDF and PNG by running Python script in the vault directory
images:
	cd vault && python3 ./scripts/generate_pdf_png2.py

clean:
	rm -rf assets/images/*
	rm -rf maps/*

# Updates _config_local.yml's exclude list with _config.yml's exclude list, and adds "assets/images"
sync-config:
	yq -i '.exclude = (load("_config.yml").exclude + ["assets/images"])' _config_local.yml

build: # careful with the keep file in config_local
	bundle exec jekyll build --config _config.yml,_config_local.yml

change-images-assets-to-symlink:
	rm -rf ./_site/assets/images
	ln -sr ./assets/images ./_site/assets/images

remove-symlink:
	rm _site/assets/images

serve: # there is a keep file in _config local that will take care of the assets images
	rm -rf ./_site/assets/images
	ln -sr ./assets/images ./_site/assets/images
	bundle exec jekyll serve --livereload --config _config.yml,_config_local.yml
