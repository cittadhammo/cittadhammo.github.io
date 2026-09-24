---
title: "{{title}}"
subtitle:
published: false
description:
author:
year:
license:
  - name:
    url:
techs:
  - name:
    url:
code:
  - name:
    url:
references:
  - name:
    title:
    url:
sources:
  - name:
    author:
    url:
images:
  - name:
    display:
    dark:
    home:
    box:
    large:
    map:
    file:
    pdf:
    svg:
    online:
    title:
    alt:
    url:
    invert_level:
      default:
      small:
      medium:
      large:
---

## Image Frontmatter Options

| Field | Default | Description |
|-------|---------|-------------|
| `display` | `true` | Show in item gallery |
| `dark` | `false` | Already-dark image; skip dark variant generation |
| `home` | `false` | Use as homepage card (generates small.webp) |
| `box` | `false` | Theme-aware lightbox (only matching variant shows) |
| `large` | `false` | Generate large.webp for higher-res lightbox |
| `map` | `false` | Generate OpenLayers map tiles + viewer page |
| `file` | `false` | Make original available for download |
| `pdf` | `false` | PDF download variant: `true` derives `<image-basename>.pdf`; a string names the file exactly |
| `svg` | `false` | SVG download variant: `true` derives `<image-basename>.svg`; a string names the file exactly |
| `url` | `""` | External link (image links out instead of lightbox) |
| `title` | `""` | Image caption |
| `alt` | `""` | Accessibility alt text |
| `background` | `"white"` | Background for map tiles |
| `lightonly` | `false` | Only in light theme |
| `darkonly` | `false` | Only in dark theme |

Thumbnail sizes (scripts/generate_assets.sh): standard 400/800/1200px, tall 565/1131/1697px.

### Download variants (`pdf` / `svg`)

Accept a boolean or a string filename. `true` derives the filename from the image basename (`<image-basename>.pdf` / `.svg`); a string is used verbatim as the filename (include the extension — nothing is appended); `false`/empty means no variant.

Requires `file: true` on the same image — without it, no download variant is copied or displayed. The pipeline copies from `vault/assets/pdfs/` (resp. `vault/assets/svgs/`) into `assets/images/<image-basename>/`.

```yaml
images:
  - name: 31-planes-A1S.png
    file: true
    pdf: true      # → 31-planes-A1S.pdf
    svg: 31-planes.svg # → exact filename, used verbatim (extension required)
```
