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

- copies the original to `assets/images/<basename>/` only for `file: true` or `.gif` images (searches recursively in `vault/assets/` if not found in `images/` subdir)
- generates `medium.webp` when `display: true` (used in item gallery)
- generates `small.webp` only for the image with `home: true` (used as homepage card)
- generates `large.webp` when `large: true` (higher-res lightbox)
- generates dark variants of all thumbnails for theme switching
- updates aspect ratios in `vault/data/size.yml`
- if `map: true`, generates tiles (Google layout) and a viewer page in `maps`
- if `url: <link>` is provided in frontmatter, the image on the site will link directly to that URL instead of opening a lightbox.

### Incremental behavior

- The script now writes `assets/images/<basename>/asset-meta.txt`.
- On later runs, unchanged images are skipped (copy, darkify, thumbnails, tiles).
- First run after this feature may regenerate everything to seed metadata.

Re-run `make assets` after content/frontmatter/image changes.

### LCP Image Preloading

To optimize Largest Contentful Paint (LCP) performance, the site automatically preloads the main chart image:
- **Automatic Preloading:** For any page using the `item` layout, the template (`_includes/head.html`) automatically scans the page's `images` list, resolves the first displayable image (skipping videos and hidden/non-displaying items), and generates a `<link rel="preload" fetchpriority="high">` tag for it.
- **Manual Override:** You can manually override the preloaded image path by adding the `lcp_preload` variable at the top-level of a page's Front Matter:
  ```yaml
  lcp_preload: "/assets/images/dhamma-citadel-A0S/medium.webp"
  ```

### Image Frontmatter Reference

Each entry in the `images` array supports these fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | — | Image filename (required) |
| `display` | bool | `true` | Show in item gallery |
| `dark` | bool | `false` | Image is already dark; skip dark variant generation |
| `home` | bool | `false` | Use as homepage card; only this image gets `small.webp` |
| `box` | bool | `false` | Theme-aware lightbox — only matching light/dark variant shows (no clone list) |
| `large` | bool | `false` | Generate `large.webp` for higher-res lightbox |
| `map` | bool | `false` | Generate OpenLayers map tiles + viewer page |
| `file` | bool | `false` | Make original file available for download |
| `pdf` | string | `""` | PDF filename for download variant |
| `svg` | string | `""` | SVG filename for download variant |
| `url` | string | `""` | External link (image becomes a link instead of opening lightbox) |
| `title` | string | `""` | Image caption / title |
| `alt` | string | `""` | Alt text for accessibility |
| `background` | string | `"white"` | Background color for map tiles |
| `lightonly` | bool | `false` | Only show in light theme |
| `darkonly` | bool | `false` | Only show in dark theme |
| `online` | bool | `false` | Image is a reference to an online resource |
| `invert_level` | object | `{}` | Per-size darkify invert level overrides (`default`, `small`, `medium`, `large`) |

Thumbnail sizes are defined in `scripts/generate_assets.sh`:
- **Standard** (aspect ratio > 0.8): small=400px, medium=800px, large=1200px
- **Tall** (aspect ratio ≤ 0.8): small=565px, medium=1131px, large=1697px

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

### Full Install (All Features)
Install all dependencies required for Jekyll, asset generation, and SVG/PDF/PNG conversion (Arch Linux):
```bash
sudo pacman -S --needed libvips go-yq gawk findutils openslide ruby ruby-bundler python-pymupdf python-yaml chromium pngquant
bundle install
```

### Partial Install
Choose the components you need:

#### Minimum for Jekyll Build/Serve
Only install what's needed to run `make build` or `make serve`:
```bash
sudo pacman -S --needed ruby ruby-bundler gawk findutils
bundle install
```

#### Add Asset Generation Support
For `make assets` (image thumbnails, map tiles):
```bash
sudo pacman -S --needed libvips go-yq openslide
```

#### Add SVG/PDF/PNG Generation Support
For `make images` (convert SVGs to PDF/PNG):
```bash
sudo pacman -S --needed python-pymupdf python-yaml chromium pngquant
```

### Jekyll

- Ruby
- Bundler

Setup:

```bash
bundle install
```

### Asset Scripts

- `vips` (libvips)
- `yq` (mikefarah/go-yq)
- `gawk`
- `findutils`
- `openslide`

Example (Arch Linux):

```bash
sudo pacman -S libvips go-yq gawk findutils openslide
```

### SVG/PDF/PNG Conversion (Optional)

For generating PDF/PNG outputs from SVGs (used by `make images`):
- `python-pymupdf`
- `python-yaml`
- `chromium`
- `pngquant` (optional, for PNG compression)

Example (Arch Linux):

```bash
sudo pacman -S python-pymupdf python-yaml chromium pngquant
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


## Original template

This is the license of the original template of the jekyll site https://github.com/arnolds/pineapple
