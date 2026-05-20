# AGENTS.md

## Overview
- This is a Jekyll site for displaying and storing Dhamma Charts and Art.
- Content is sourced from an Obsidian vault that is synced from another repo.
- Sites uses the Pineapple Jekyll template.

## New Configuration Options
- `site.theme.scroll_reveal`: Set to `false` in `_config.yml` to disable all ScrollReveal animations site-wide.
- `reveal-first`: A CSS class used for the very first visible item in the gallery to ensure it animates instantly without waiting for JS.

## Dark Mode Improvements
- A `MutationObserver` in `head.html` intercepts and swaps image `src` for dark variants as they are parsed, preventing any flicker of light variants on load.
- Manual variants (`lightonly: true`, `darkonly: true` in frontmatter) are handled via inline CSS in the head and the `updateLightDarkOnlyItems` function.
- Cloudflare Web Analytics is enabled via `site.cloudflare_analytics_token` in `_config.yml`.

## Key Structure
- Content lives in `vault/content` (markdown with YAML frontmatter).
- Source images live in `vault/assets/images` and generated assets go to `assets/images`.
- Map viewer pages are generated into `maps` from `scripts/map-template.html`.
- Site layouts and includes are in `_layouts` and `_includes`.
- Styles are in `assets/scss/_custom.scss` and pulled by `assets/css/style.scss`.
- Project documentation files in root (GEMINI.md, AGENTS.md, OPTIMISATION*.md, etc.) are excluded from the Jekyll build.


- `external_links`: Add to an area in `vault/data/areas.yml` to render external links in the area header alongside regular pages. Each entry needs `title` and `url`:
  ```yaml
  - name: charts
    pages:
      - name: links
    external_links:
      - title: Old Site
        url:   https://dhammacharts.github.io/
  ```
  Links open in a new tab via `target="_blank"`.

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

## PDF/PNG Generation (vectors)
- Source SVGs live in `vault/assets/svgs/<name>.svg` (without format codes).
- Configuration in `vault/data/vectors.yml` defines which SVGs to generate:
  ```yaml
  vectors:
    - name: DhammaCitadel
      formats:
        - A0S
        - A0SM
        - A0SBM
  ```
- Format codes: A0S, A0V, A0H, A1S, A1V, A1H, A2S, A2V, A2H, 2A0S, 2A0V, 2A0H
  - Add `B` for black background (e.g., A0SB)
  - Add `M` for margin (e.g., A0SM, A0SBM)
- Generated outputs go to `vault/assets/{pdfs,images,wrappers}/<name>-<label>.*`
- Run `make images` from project root to generate.
- License overlay on generated output is opt-in via `vault/data/vectors.yml`. Set `license: true` to use the `defaults.license` settings, or `license: { key: value }` to override specific settings (e.g., `scale`, `padding`). If absent, no wrapper overlay is added (most SVGs already have license text baked into the source file).

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
