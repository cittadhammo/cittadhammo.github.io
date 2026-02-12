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

- `[[DhammaCharts.org]]` for project/site context
- `[[CHECK]]` for pending tasks and attention points

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

### Dependencies

```bash
pip3 install pymupdf
sudo apt install chromium-browser
```

### Filename Convention

Each SVG filename should start with a format code describing paper size, orientation, background, and margin.

Format:

- `A[0-2]x[B][M]-name.svg`
- `2A0x[B][M]-name.svg`

Legend:

- `A0`, `A1`, `A2`, `2A0`: paper size
- `V`, `H`, `S`: Vertical / Horizontal / Square
- `B` (optional): black background
- `M` (optional): add 1 cm margin

Examples:

- `A1V-map.svg` -> A1 vertical, white background, no margin
- `A0HBM-graph.svg` -> A0 horizontal, black background, margin
- `2A0S-design.svg` -> 2A0 square, white background, no margin
- `A2VBM-sketch.svg` -> A2 vertical, black background, margin

Naming note:

- Files usually start with a capital letter and CamelCase.

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
