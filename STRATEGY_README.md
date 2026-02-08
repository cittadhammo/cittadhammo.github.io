# Current State of Lightbox and Map Integration (as of February 8, 2026):

This document outlines the current implementation status and changes made related to the lightbox feature and map image handling.

## 1. Lightbox Implementation

*   **Library:** Magnific Popup (v1.1.0) is integrated locally.
    *   **CSS:** `assets/css/vendor/magnific-popup.min.css`
    *   **JS:** `assets/scripts/vendor/jquery.magnific-popup.min.js`
*   **Inclusion:**
    *   Magnific Popup CSS is included via `<link rel="stylesheet" href="{{ '/assets/css/vendor/magnific-popup.min.css' | prepend: site.baseurl }}">` in `_includes/head.html`.
    *   Magnific Popup JS and custom `lightbox.js` are included in `_layouts/item.html` after jQuery.
*   **Initialization (`lightbox.js`):** Initializes Magnific Popup on `.lightbox-gallery` elements, delegating events to `a.mfp-image`. This creates a gallery for standard images.

## 2. Image Display in `_layouts/item.html`

*   Images are iterated from `page.images` in the frontmatter.
*   Only images with `display != false` are rendered.
*   **Non-map images (`else` block):**
    *   Wrapped in `<a class="mfp-image">` (triggers image lightbox).
    *   Links to large thumbnail (`/assets/images/{{ img }}/large.{{site.img_ext}}`).
*   **Map images (`if image.map` block):**
    *   The main image is wrapped in `<a class="black-under">` and links directly to the map HTML page (`{{site.baseurl}}/maps/{{img}}.html`).
    *   **Fullscreen Icon Overlay (`map-icon-overlay`):**
        *   A separate `<a>` tag (`class="map-icon-overlay load-hidden"`) contains the `fullscreen.png` icon.
        *   **Current inline styles:** `position: absolute; top: 10px; right: 10px; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; opacity: 1 !important;`
        *   The nested `<img>` has `style="width: 24px; height: 24px;"`.
        *   This icon links directly to `{{site.baseurl}}/maps/{{img}}.html`.
        *   It has the `load-hidden` class for `scrollreveal` animation (positional animation, as `opacity: 1 !important;` overrides `scrollreveal`'s fade-in effect).
        *   The user intends to provide a white background directly within `fullscreen.png`.

## 3. Cursor and Visual Fixes

*   **`assets/scss/_custom.scss` rules:**
    *   `cursor: pointer !important;` for `.mfp-close` (close button).
    *   `cursor: default !important;` for `.mfp-wrap.mfp-zoom-out-cur`, `.mfp-bg`, and `.mfp-zoom-out-cur` to override zoom cursors in the lightbox overlay.
    *   Removed hover effect for `map-icon-overlay` as the user plans to manage the background via the PNG itself.

## 4. Typography Changes

*   **`assets/scss/_core.scss`:**
    *   `body` line-height set to `1.1`.
    *   `p` has `padding-bottom: 1rem;`.
*   **`assets/scss/_layout.scss`:**
    *   `.project .h2` has `margin: 1.2rem 0 1rem;` (increased bottom margin).

---

## Next Steps: Map in Lightbox (New Strategy)

The user wants to display `map.html` content within the Magnific Popup lightbox. This will involve:

1.  **Modify `_layouts/item.html`**:
    *   Add `class="mfp-iframe"` to both the main `<a>` tag wrapping the map image and the `map-icon-overlay` `<a>` tag. This indicates that these links should be opened as iframes by Magnific Popup.
2.  **Modify `assets/scripts/lightbox.js`**:
    *   Update the Magnific Popup initialization. The `delegate` option will be expanded to include `a.mfp-iframe`.
    *   A `callbacks.elementParse` function will be added to dynamically determine the content `type` (`'image'` or `'iframe'`) based on the class of the clicked element.
3.  **Locate Map Template:** Find the Jekyll template responsible for generating the `map.html` pages (e.g., `map-template.html`).
4.  **Add Fullscreen Button to Map Template:** Implement an HTML button within the map template that triggers fullscreen mode for the map content.
5.  **Implement Fullscreen JavaScript:** Add JavaScript to the map template to handle the browser's Fullscreen API for the fullscreen button.
