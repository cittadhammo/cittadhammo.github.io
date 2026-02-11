# AGENTS.md

## Overview
- This is a Jekyll site for displaying and storing Dhamma Charts and Art.
- Content is sourced from an Obsidian vault that is synced from another repo.
- The site uses the Pineapple Jekyll template.

## Key Structure
- Content lives in `vault/content` (markdown with YAML frontmatter).
- Source images live in `vault/assets/images` and generated assets go to `assets/images`.
- Map viewer pages are generated into `maps` from `scripts/map-template.html`.
- Site layouts and includes are in `_layouts` and `_includes`.
- Styles are in `assets/scss/_custom.scss` and pulled by `assets/css/style.scss`.

## Content Model
- “Areas” are top-level collections. To add a new area:
- Create `area_name.md` at the repo root with `title` and `area` frontmatter.
- Add a collection to `_config.yml`.
- Update `content/_data/areas.yml`.
- Pages in collections need frontmatter `type: page` to appear in the top-right area navigation.
- Categories are inferred from content paths.

## Asset Generation
- Main asset pipeline is `scripts/generate_assets.sh` and `make assets`.
- It scans all markdown in `vault/content`, reads frontmatter `images`, and for each image:
- Copies the original to `assets/images/<basename>`.
- Generates `small.webp`, `medium.webp`, and `large.webp` thumbnails.
- Writes aspect ratios to `vault/data/size.yml`.
- If an image is marked `map: true`, it generates map tiles and a viewer page in `maps`.
- Map viewers use OpenLayers with the template `scripts/map-template.html`.

## Development
- Primary commands are in `Makefile`.
- `make serve` runs Jekyll with livereload and symlinks `assets/images` into `_site`.
- `make build` builds with `_config.yml` + `_config_local.yml`.
- `make clean` removes generated images and map pages.
- `make images` runs a Python script in `vault/scripts` to generate PDF/PNG assets.

## Dependencies
- Ruby + Bundler for Jekyll (`bundle install`, then `bundle exec jekyll serve`).
- Asset scripts require `vips`, `yq` (mikefarah), `gawk`, `findutils`, and `openslide`.

## Config Notes
- Local serve uses `_config.yml` and `_config_local.yml`.
- For root-domain deployments, set `baseurl` in `_config.yml` to an empty string.
- Jekyll keeps generated assets via `keep_files` and a symlink trick in `make serve`.

## Gotchas
- Do not use Liquid comments `{# #}` inside page code; they break parsing.
- Generated files live under `assets/images` and `maps`; rerun `make assets` after content or image changes.
- Do not run git commands; the user will handle git operations manually.

## Ignore
- `_archive` is legacy and should be ignored.
