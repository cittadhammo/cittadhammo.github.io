# Chromium Print-to-PDF Border Artifact

## The Bug

When using Chromium headless `--print-to-pdf` to render SVG wrappers, the right and bottom edges of the generated PDF get an anti-aliased gray/white border (~1px wide). This is a known Chromium rendering artifact — the SVG content shifts ~1px down/right during PDF generation, exposing a gray transition between the black SVG content and the white page background.

**Pixels at the edge** (7015×7015 PNG @ 300 DPI):
| Edge | Before Fix | After rsvg-convert |
|------|-----------|-------------------|
| Top | 1 white, rest black | all black |
| Bottom | **all white** | all black |
| Left | 1 white, rest black | all black |
| Right | **all white** | all black |

## Strategies Explored

### 1. Chromium `--print-to-pdf` (original — current `generate_pdf_png.py`)

**How it works:** HTML wrapper embeds SVG via `<object>` tag with Google Fonts loaded in the `<head>`. Chromium renders the page and prints to PDF. PNG is extracted from PDF via PyMuPDF.

**Pros:** ✅ Web fonts (Poppins) render correctly  
**Cons:** ❌ Gray/white border on right and bottom edges

**Dependencies:** `chromium`, `python3-fitz` (PyMuPDF)

---

### 2. rsvg-convert (V2 — saved as `generate_pdf_png_v2.py`)

**How it works:** SVG is rendered directly to PNG via `rsvg-convert --format png` at 300 DPI. The HTML wrapper is still used for Chromium PDF generation.

**Pros:** ✅ Clean edges, pure black  
**Cons:** ❌ Web fonts not loaded (Poppins falls back to system font), even if `@font-face` with base64 data URIs is embedded in the SVG (librsvg 2.61 may have limited support)

**Dependencies:** `librsvg` (`rsvg-convert`), `chromium`, `python3-fitz`

---

### 3. Chromium `--print-to-pdf` + oversize page (untested)

**How it works:** Same HTML wrapper, but set `@page { size: 595mm 595mm; }` (1mm larger) with `background: black` and `overflow: hidden`. The SVG stays at 594×594mm centered. The extra 0.5mm on each edge absorbs the artifact into the black background.

**Pros:** ✅ Web fonts work, no extra dependencies, minimal change  
**Cons:** ❓ Untested — depends on whether the artifact is within the 0.5mm bleed

**Dependencies:** `chromium`, `python3-fitz`

---

### 4. Chromium `--screenshot` (untested)

**How it works:** Instead of `--print-to-pdf`, use Chromium headless `--screenshot` at the target size with `--window-size=7015,7015` and `--force-device-scale-factor=1`. Captures a direct PNG of the rendered page, bypassing the PDF rendering pipeline.

**Pros:** ✅ Web fonts work, likely no border artifact  
**Cons:** ❓ Untested — may have scaling quirks at non-standard DPI

**Dependencies:** `chromium`

---

### 5. Inkscape CLI (untested)

**How it works:** Use `inkscape --export-type=png --export-width=7015 --export-height=7015` to render SVG directly.

**Pros:** ✅ Clean edges  
**Cons:** ❌ Web fonts not loaded (same font issue as rsvg-convert, despite Inkscape using its own renderer)  
⚠️ Emitted a warning: *"Unimplemented style property 7 — SPIFilter::read(): malformed value: invert(1)"*

**Dependencies:** `inkscape`

---

### 6. Hybrid — Chromium PDF + rsvg PNG (current V2 approach)

**How it works:** PDF generated via Chromium (vector format, border artifact is negligible at the vector level). PNG generated via rsvg-convert (clean edges).

**Pros:** ✅ Clean PNG, PDF works  
**Cons:** ❌ PNG has fallback fonts  
❌ Two different renderers produce slightly different results

**Dependencies:** `librsvg`, `chromium`, `python3-fitz`

## Recommendation

**Option 3 (oversize page)** is the most promising: minimal change, keeps fonts, no new dependencies. The fix is trivial — add 1mm to `@page` size in the HTML template and keep the SVG centered. This should absorb Chromium's 1px shift into the black background.

If Option 3 fails, **Option 4 (screenshot)** is the next best bet, as it bypasses the PDF pipeline entirely while keeping Chromium's font loading.
