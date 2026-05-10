# License/Icon Overlay Feature Plan

## Overview
Add an optional overlay feature to place a license badge (text + icon) on generated PDFs/PNGs. Supports both text and SVG icons with custom Google Fonts.

## Requirements

1. **Both text and icon**: Support for text-only, icon-only, or both together
2. **SVG icons**: Different badges for different charts (stored in vault/assets/icons/)
3. **Google Font**: Poppins (with weight variants)
4. **Hierarchical config**: Per-vector options in `vectors.yml` with fallback to global defaults

---

## Files to Create/Modify

### 1. `vault/data/vectors.yml` - Schema Update

```yaml
defaults:
  icon:
    font: "Poppins"
    font_size: 10          # mm
    color: "#333333"
    background: "rgba(255,255,255,0.8)"
    position: "bottom-right"
    padding: 8             # mm from edges
    opacity: 1.0

vectors:
  - name: dhamma-citadel
    formats:
      - A0S
      - A0SM
    icon:
      text: "© 2026 Dhamma Charts"
      icon: "cc-by"           # references vault/assets/icons/cc-by.svg
      # inherits all other defaults

  - name: dhamma-citadel-bw
    formats:
      - A0S
    icon:
      text: "© 2026 Dhamma Charts"
      icon: "cc-by"
      color: "#ffffff"        # override for black background variant
      position: "bottom-left" # override position

  - name: bhikkhu-patimokkha
    formats:
      - A1S
    icon:
      # no text, icon only
      icon: "pd"             # public domain badge
      position: "top-right"
```

### 2. `vault/assets/icons/` - Icon Storage

```
vault/assets/icons/
  cc-by.svg        # Creative Commons Attribution
  cc-by-sa.svg     # Creative Commons Attribution-ShareAlike
  pd.svg           # Public Domain
  custom.svg       # Generic badge
```

### 3. `vault/scripts/generate_pdf_png.py` - Core Logic

Key changes:
- Load global `defaults.icon` from config
- Deep-merge per-vector `icon` overrides
- Generate HTML overlay element with:
  - Inline SVG icon (embedded)
  - Text with Google Font via CSS `@import`
  - CSS positioning based on `position` + `padding`
  - Optional background for legibility

### 4. `Makefile` - No changes needed

---

## HTML Overlay Implementation

### Template Addition

```html
<style>
  @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap');

  .license-overlay {
    position: absolute;
    display: flex;
    align-items: center;
    gap: 4px;
    font-family: 'Poppins', sans-serif;
    font-size: 10mm;
    color: #333333;
    background: rgba(255, 255, 255, 0.8);
    padding: 4px 8px;
    border-radius: 4px;
  }

  .license-overlay.top-right { top: 8mm; right: 8mm; }
  .license-overlay.top-left  { top: 8mm; left: 8mm; }
  .license-overlay.bottom-right { bottom: 8mm; right: 8mm; }
  .license-overlay.bottom-left  { bottom: 8mm; left: 8mm; }

  .license-overlay svg {
    width: 12mm;
    height: 12mm;
  }
</style>

<div class="license-overlay bottom-right">
  <svg><!-- inline icon content --></svg>
  <span>© 2026 Name</span>
</div>
```

---

## Step-by-Step Implementation

- [ ] **Step 1**: Create `vault/assets/icons/` directory and add placeholder SVG icons
- [ ] **Step 2**: Update `vectors.yml` schema with `defaults` section and per-vector `icon` options
- [ ] **Step 3**: Modify `generate_pdf_png.py`:
  - [ ] Load and merge icon config (global defaults + per-vector overrides)
  - [ ] Load icon SVG content
  - [ ] Generate overlay HTML with CSS positioning
  - [ ] Handle missing optional fields gracefully
- [ ] **Step 4**: Test with one vector, verify output
- [ ] **Step 5**: Apply to remaining vectors as needed

---

## Position Values

| Value | Description |
|-------|-------------|
| `top-left` | Top-left corner |
| `top-right` | Top-right corner |
| `bottom-left` | Bottom-left corner |
| `bottom-right` | Bottom-right corner (default) |
| `center` | Dead center (rarely used) |

---

## Example Output Structure

```yaml
# vault/data/vectors.yml
defaults:
  icon:
    font: "Poppins"
    font_size: 10
    color: "#333333"
    background: "rgba(255,255,255,0.85)"
    position: "bottom-right"
    padding: 10
    opacity: 1.0

vectors:
  - name: dhamma-citadel
    formats:
      - A0S
      - A0SM
    icon:
      text: "© 2026 Dhamma Charts"
      icon: "cc-by"

  - name: manual-buddhist-terms
    formats:
      - A1S
    icon:
      text: "© 2026 Dhamma Charts"
      icon: "cc-by-sa"
      position: "bottom-left"  # different position

  - name: sutta-pitaka
    formats:
      - A0VM
    # no icon - omit entirely
```

---

## Edge Cases

1. **No icon configured**: Generate as before (no overlay)
2. **Icon file not found**: Log warning, skip icon, render text-only
3. **Empty text with icon**: Render icon only
4. **Black background variants**: Consider `color` override (e.g., white on black)

---

## Session Continuation

This plan was created during session: [date to be filled]

Current state:
- [x] Requirements gathered
- [x] Plan documented
- [ ] Implementation pending
