# AVIF Implementation Plan for Dhammacharts

This document outlines the strategy for incorporating the AVIF image format into the Dhammacharts website to achieve superior compression while maintaining compatibility via WebP fallbacks.

## 1. Objectives
- **Superior Compression:** Leverage AVIF for 20-30% smaller file sizes compared to WebP.
- **Maintain Compatibility:** Use WebP as a fallback for browsers that do not yet support AVIF.
- **Theme Support:** Ensure both AVIF and WebP variants support Light/Dark mode switching.
- **Automated Workflow:** Integrate AVIF generation into the existing `generate_assets.sh` script.
- **Simplified Assets:** Focus only on **Small** and **Medium** variants; the "Large" variant has been phased out.

## 2. Component Changes

### A. Asset Generation (`scripts/generate_assets.sh`)
**Changes:**
- Define paths for AVIF thumbnails (`small.avif`, `medium.avif`).
- Add `vips thumbnail` commands to generate AVIF variants with optimized quality settings (`Q=75`).
- Update the `darkify_image` logic to process AVIF thumbnails.
- Update the "Up-to-Date" check to include AVIF files.

### B. Theme-Switching Logic (`_includes/head.html`)
**Changes:**
- Update the `updateThemeImages` JavaScript function to handle `<picture>` tags.
- The function must now iterate through `<source>` elements and update their `srcset` attributes based on new `data-light-srcset` and `data-dark-srcset` attributes.

### C. Liquid Templates (`_includes/itemsList.html`, `_includes/item-gallery.html`)
**Changes:**
- Replace standalone `<img>` tags with `<picture>` blocks.
- Add `<source>` tags for AVIF and WebP.
- Use data attributes to facilitate JS-based theme switching:
  ```html
  <picture>
    <source type="image/avif" 
            srcset=".../small.avif" 
            data-light-srcset=".../small.avif" 
            data-dark-srcset=".../small-dark.avif">
    <source type="image/webp" 
            srcset=".../small.webp" 
            data-light-srcset=".../small.webp" 
            data-dark-srcset=".../small-dark.webp">
    <img src=".../small.webp" ...>
  </picture>
  ```

### D. Lightbox Integration (`_includes/item-gallery.html`)
**Changes:**
- The lightbox currently relies on `data-light-href` and `data-dark-href`.
- Since "Large" is removed, ensure all lightbox triggers point to the **Medium** variant for both WebP and (eventually) AVIF.

## 3. Implementation Steps (Phased)

### Phase 1: Infrastructure
1.  **Modify `scripts/generate_assets.sh`:** Implement AVIF generation for small/medium.
2.  **Run `make assets`:** Generate the new files.

### Phase 2: Core Logic
1.  **Update `_includes/head.html`:** Refactor `updateThemeImages` to support `<picture>` and `<source>` tags.

### Phase 3: Content Templates
1.  **Refactor `_includes/itemsList.html`:** Implement `<picture>` tags for the home/area galleries.
2.  **Refactor `_includes/item-gallery.html`:** Implement `<picture>` tags for the item detail pages.

### Phase 4: Validation
1.  **Validation:** Test across different browsers (Chrome, Safari, Firefox) and theme modes.

## 4. Technical Snippet: Updated `updateThemeImages`
```javascript
function updateThemeImages(theme) {
  var isDark = theme === "dark";
  
  // Update Source tags inside Pictures
  var sources = document.querySelectorAll("picture source[data-light-srcset]");
  sources.forEach(function(source) {
    var light = source.getAttribute("data-light-srcset");
    var dark = source.getAttribute("data-dark-srcset") || light;
    var next = isDark ? dark : light;
    if (next && source.getAttribute("srcset") !== next) {
      source.setAttribute("srcset", next);
    }
  });

  // Update Img tags (Fallback and non-picture)
  var images = document.querySelectorAll("img[data-light-src]");
  images.forEach(function (img) {
    var lightSrc = img.getAttribute("data-light-src");
    var darkSrc = img.getAttribute("data-dark-src") || lightSrc;
    var nextSrc = isDark ? darkSrc : lightSrc;
    if (nextSrc && img.getAttribute("src") !== nextSrc) {
      img.setAttribute("src", nextSrc);
    }
  });
}
```
