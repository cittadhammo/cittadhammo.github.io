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
| `pdf` | `""` | PDF filename for download variant |
| `svg` | `""` | SVG filename for download variant |
| `url` | `""` | External link (image links out instead of lightbox) |
| `title` | `""` | Image caption |
| `alt` | `""` | Accessibility alt text |
| `background` | `"white"` | Background for map tiles |
| `lightonly` | `false` | Only in light theme |
| `darkonly` | `false` | Only in dark theme |

Thumbnail sizes (scripts/generate_assets.sh): standard 400/800/1200px, tall 565/1131/1697px.
