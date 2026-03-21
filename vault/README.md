> Going and coming freely, the substance of mind without blockage: this is prajna.
>
> — Huineng

---

## Purpose

This vault is the content base for `dhammacharts.org`, built with Jekyll (Pineapple template, customized).

The goal is to keep content easy to maintain through:

- Obsidian
- GitHub Web UI

Useful pages:

- [[DhammaCharts.org]] for project/site context

## Plugins

Install [obsidian-eln-plugin](https://github.com/fcskit/obsidian-eln-plugin) for easy management of nested properties of items. (manual install works well) OR use https://github.com/cittadhammo/obsidian-nested-properties/tree/fix/add-item-button-for-list-properties

Add [Data file editor](https://github.com/ZukTol/obsidian-data-files-editor) plugin to edit `.yml` file

Add Excalidraw

## Publishing and Site Build Notes

Main asset/build flow:

- The Jekyll + Bash asset script generates:
  - thumbnails (`small`, `medium`, `large`)
  - tiled maps
  - lightbox assets
- Original files remain downloadable from item pages.

Frontmatter publishing controls:

- `published: false` to hide an item from the site
- `draft: true` can also be used for work-in-progress content

## SVG to PDF/PNG Converter

The SVG converter batch-generates high-resolution PDF and PNG outputs using Chromium + PyMuPDF.

Configuration:

- Source SVGs: `vault/assets/svgs/<name>.svg` (without format codes)
- Config: `vault/data/vectors.yml`

### vectors.yml Format

```yaml
vectors:
  - name: DhammaCitadel
    formats:
      - A0S
      - A0SM
      - A0SBM
```

Format codes:
- `A0`, `A1`, `A2`, `2A0`: paper size
- `V`, `H`, `S`: Vertical / Horizontal / Square
- `B`: black background
- `M`: add 1 cm margin

Generated outputs go to `vault/assets/{pdfs,images,wrappers}/<name>-<label>.*`

### Dependencies

```bash
# Arch Linux
sudo pacman -S python-pymupdf python-yaml chromium

# Debian/Ubuntu
sudo apt install python3-pymupdf python3-yaml chromium

# PNG compression (optional)
sudo pacman -S pngquant  # or: sudo apt install pngquant
```

### Make Commands

```bash
make images              # Generate PDF/PNG with lossy compression
make images-uncompressed  # Generate without compression
make images-uncompressed-lossless  # Generate with lossless compression
```

## Frontmatter Notes

Obsidian still has limitations with nested properties/collections in frontmatter preview, so structured frontmatter is kept for site generation.

For images, you can use normal names or wikilink-style names in image fields (for example `image.png` or `[[image.png]]`), while keeping structured properties when options per image are needed.

## Templates

- Home Page
- Area Page
- Item Page
- Reference Page
- Reference
- Page from item list

## Tree Structure

### Charts

#### Digital

```dataview
list from "content/_charts/digital"
```

#### By Others

```dataview
list from "content/_charts/by-others"
```

#### Hand Made

```dataview
list from "content/Charts/Hand Made"
```
