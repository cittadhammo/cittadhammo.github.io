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

## Tip

Install https://github.com/fcskit/obsidian-eln-plugin for easy management of nested properties of items. (manual install works well)

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

Behavior:

- Wraps each SVG in an HTML template
- Supports margins and standard paper formats
- Renders PDF via headless Chromium
- Exports PNG at 300 DPI with matching pixel dimensions
- If no A-format is found in filename, defaults to `A1V`

### Dependencies (Arch Linux)

```bash
sudo pacman -S python-pymupdf chromium
```

### Optional Dependencies

For PNG compression (optional):

```bash
# Arch Linux
sudo pacman -S pngquant

# Debian/Ubuntu
sudo apt install pngquant

# macOS
brew install pngquant
```

### Make Commands

```bash
make images              # Generate PDF/PNG without compression
make images-compressed   # Generate with lossless compression (quality=100)
make images-compressed-lossy  # Generate with lossy compression (quality=70-90)
```

Or run directly:

```bash
cd vault && python3 ./scripts/generate_pdf_png.py
cd vault && python3 ./scripts/generate_pdf_png.py --compression lossless
cd vault && python3 ./scripts/generate_pdf_png.py --compression lossy
```

### Filename Convention

Each SVG filename should end with a format code describing paper size, orientation, background, and margin.

Format:

- `<name>-A[0-2][V|H|S][B][M].svg`
- `<name>-2A0[V|H|S][B][M].svg`

Legend:

- `A0`, `A1`, `A2`, `2A0`: paper size
- `V`, `H`, `S`: Vertical / Horizontal / Square
- `B` (optional): black background
- `M` (optional): add 1 cm margin

Examples:

- `map-A1V.svg` -> A1 vertical, white background, no margin
- `graph-A0HBM.svg` -> A0 horizontal, black background, margin
- `design-2A0S.svg` -> 2A0 square, white background, no margin
- `sketch-A2VBM.svg` -> A2 vertical, black background, margin
- `myChart-it-A0BM.svg` -> A0 vertical, black background, margin

Naming note:

- Any descriptive name can be used before the final `-<format>` suffix.

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
