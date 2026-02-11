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
make assets       # Generate/copy image assets + map tiles/viewers
make images       # Generate PDF/PNG assets from vault script
make build        # Jekyll build with _config.yml + _config_local.yml
make serve        # Local serve with livereload + assets symlink into _site
make clean        # Remove generated assets/images and maps
make sync-config  # Sync exclude list into _config_local.yml (+ assets/images)
```

## Asset Pipeline

`scripts/generate_assets.sh` scans markdown frontmatter `images` entries and:

- copies original image files into `assets/images/<basename>/`
- generates `small.webp`, `medium.webp`, `large.webp` when `display: true`
- updates aspect ratios in `vault/data/size.yml`
- if `map: true`, generates tiles (Google layout) and a viewer page in `maps`

Re-run `make assets` after content/frontmatter/image changes.

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
