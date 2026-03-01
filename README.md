# DhammaCharts

Jekyll site for publishing Dhamma charts, writings, references, and 3D printing resources.

## Project Structure

- Content: `vault/content` (markdown with frontmatter)
- Source images: `vault/assets/images`
- Generated image assets: `assets/images`
- Generated map viewer pages: `maps`
- Area/site data: `vault/data`
- Layouts/includes: `_layouts`, `_includes`
- Main custom styles: `assets/scss/_custom.scss`
- Asset/map pipeline script: `scripts/generate_assets.sh`
- Map viewer template: `scripts/map-template.html`

## Content Model

- Areas are configured in `vault/data/areas.yml`.
- Each area maps to a Jekyll collection in `_config.yml`.
- Category is inferred from content path.
- Collection documents with `type: page` appear in the area header links.

### Add a New Area

1. Create a new collection folder in `vault/content` named `_<area-name>/`.
2. Add the collection in `_config.yml`.
3. Add the area and categories in `vault/data/areas.yml`.
4. Add markdown files in the new folder with frontmatter (`title`, `images`, etc.).
5. For area header links, set `type: page` on collection docs that should appear there.

## Commands

```bash
make help         # Show all make commands and variables
make assets       # Generate/copy image assets + map tiles/viewers
make maps-html    # Regenerate map HTML only (no tiles/thumbnails)
make images       # Generate PDF/PNG assets from vault script
make images-uncompressed          # Generate with script default compression mode
make images-uncompressed-lossless # Generate with lossless compression
make images-compressed-lossy      # Generate with lossy compression
make build        # Jekyll build with _config.yml + _config_local.yml
make serve        # Local serve with livereload + assets symlink into _site
make clean        # Remove generated assets/images and maps
make sync-config  # Sync exclude list into _config_local.yml (+ assets/images)
make darkify-test # Compare all darkify methods on test images
make darkify-test-thumbnails # Test original + small/medium/large dark variants
make structure    # Sync all collection/folder/category/page refs into _config.yml and areas.yml
make structure-check # Check if _config.yml and areas.yml are in sync with vault/content
make structure-sync-check # Sync and then verify consistency
```

## Asset Pipeline

`scripts/generate_assets.sh` scans markdown and processes images from:

- frontmatter `images` entries
- frontmatter `image` (single image)
- page content wikilinks (for example `[[image.png]]`, `[[image]]`, `![[image]]`)

For each image it:

- copies original image files into `assets/images/<basename>/`
- generates `small.webp`, `medium.webp`, `large.webp` when `display: true`
- updates aspect ratios in `vault/data/size.yml`
- if `map: true`, generates tiles (Google layout) and a viewer page in `maps`

### Incremental behavior

- The script now writes `assets/images/<basename>/asset-meta.txt`.
- On later runs, unchanged images are skipped (copy, darkify, thumbnails, tiles).
- First run after this feature may regenerate everything to seed metadata.

Re-run `make assets` after content/frontmatter/image changes.

### Darkify Test Harness

- Put test images in `scripts/darkify-test/input/`.
- Run:

```bash
make darkify-test
make darkify-test-thumbnails
```

Equivalent direct script command:

```bash
bash scripts/darkify-test/run.sh
bash scripts/darkify-test/run-thumbnails.sh
```

- Method comparison outputs are written to `scripts/darkify-test/output/<image-base>/`.
- Thumbnail/original outputs are written to `scripts/darkify-test/output-thumbnails/<image-base>/`.
- Invert-lightness levels are configured in `_config.yml` under `darkify.invert_level`.
- `make help` shows test variables (`DARKIFY_TEST_INPUT`, `DARKIFY_TEST_OUTPUT`, `DARKIFY_THUMBS_OUTPUT`, `DARKIFY_CONFIG_FILE`) and optional override vars (`DARKIFY_INVERT_LEVEL_*`).

## Dependencies

### Jekyll

- Ruby
- Bundler

Setup:

```bash
bundle install
```

### Asset scripts

- `vips` (libvips)
- `yq` (mikefarah/go-yq)
- `gawk`
- `findutils`
- `openslide`

Example (Arch Linux):

```bash
sudo pacman -S libvips go-yq gawk findutils openslide
```

## Configuration Notes

- Local build/serve uses `_config.yml,_config_local.yml`.
- For root-domain deploys, set `baseurl: ""` in `_config.yml`.
- Generated assets are preserved during serve via symlink logic in `make serve`.

## Footer Blocks

Footer content is driven by `_config.yml` under `footer.blocks`.

Each block supports:
- `title`: block heading
- `items`: list of rows

Each item supports:
- `type: email_obfuscated` (anti-scraping display, uses RTL obfuscation)
- `type: link` (`label`, `url` or `source_key`, plus optional `external`, `relative_url`, `title`)
- text row (omit `type`, use `text` or `value`)

Example:

```yml
footer:
  blocks:
    - title: "Contact"
      items:
        - type: email_obfuscated
          source_key: email
    - title: "Connect"
      items:
        - type: link
          label: "Discord"
          source_key: discord_url
          external: true
        - type: link
          label: "Contribute"
          source_key: contribute_url
          relative_url: true
    - title: "Info"
      items:
        - text: "Dhamma Charts and Art."
        - type: link
          label: "About"
          url: "/charts/about.html"
          relative_url: true
```

## Local Mirror

```bash
wget \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  http://localhost:4000/
```

## Arch Ruby PATH Note

If gem executables are not found on Arch, this can help:

```bash
echo 'export PATH="$PATH:$(ruby -e "puts Gem.user_dir")/bin"' >> ~/.$(basename $SHELL)rc
```

## Notes

- Avoid Liquid comments using `{# #}` inside page code.
- `_archive` is legacy.

## Publishing Note

Add `"gh-pages"` or `"cf-pages"` keywords in the commit message to trigger the related GitHub Actions publishing workflow.

### Workflow flags and behavior

- Add `"force-assets"` in the commit message to force full asset regeneration in CI.
- Without `force-assets`, CI runs asset generation only when asset-related files changed.
- CI restores cached generated assets from deploy branch (`gh-pages` / `cf-pages`) before deciding whether to regenerate.
- If cache is missing, CI auto-falls back to full asset generation.

## Page Layout Image Wikilinks

For documents using `layout: page`, image wikilinks in markdown content are rendered as images and included in a lightbox gallery across the page images.

Supported examples:

- `[[image.png]]`
- `[[image]]`
- `![[image]]`

Could use a container in the workflow for more stable builds, for example:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ruby:3.2-bookworm

    steps:
      - uses: actions/checkout@v4

      - name: Install libvips
        run: apt-get update && apt-get install -y libvips-tools

      - name: Install Bundler (optional but recommended)
        run: gem install bundler

      - name: Build Jekyll site
        run: bundle exec jekyll build --config _config.yml,_config_gh.yml
```
