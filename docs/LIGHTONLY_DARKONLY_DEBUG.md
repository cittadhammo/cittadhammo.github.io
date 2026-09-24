# Lightonly/Darkonly Image Debug Notes

## Goal
Add `lightonly: true` and `darkonly: true` properties to images in the frontmatter. These images should:
- Only appear in the aside gallery in their respective theme mode
- Always be available in the lightbox gallery
- Not cause page loading flicker (images should not appear before header/body)
- Show properly when toggling themes without JavaScript delay

## Current Implementation

### Frontmatter property (item-gallery.html)
Images can have `lightonly: true` or `darkonly: true`:
```yaml
images:
  - name: image-light-A1S.png
    lightonly: true
  - name: image-dark-A1S.png
    darkonly: true
```

This adds CSS classes `lightonly-item` or `darkonly-item` to the `<li>` element.

### CSS in head.html (inline, loads immediately)
```html
<style>
  html[data-theme="dark"] img[data-dark-src]:not([data-theme-image-ready="true"]):not(.home-hero-logo) {
    opacity: 0;
  }
  /* Default display when data-theme not yet set (assumes light mode) */
  .lightonly-item { display: list-item !important; }
  .darkonly-item { display: none !important; }
  /* Theme-specific overrides - using !important to override ScrollReveal */
  [data-theme="dark"] .lightonly-item { display: none !important; }
  html[data-theme="light"] .darkonly-item { display: none !important; }
  [data-theme="dark"] .darkonly-item { display: block !important; }
  [data-theme="dark"] .darkonly-item li { display: block !important; }
  html[data-theme="light"] .lightonly-item { display: block !important; }
  html[data-theme="light"] .lightonly-item li { display: block !important; }
  /* Override ScrollReveal transforms and visibility */
  .lightonly-item img, .darkonly-item img { transform: none !important; }
  .lightonly-item img, .lightonly-item .map-icon,
  .darkonly-item img, .darkonly-item .map-icon {
    visibility: inherit !important;
    opacity: 1 !important;
  }
  [data-theme="dark"] .darkonly-item img, [data-theme="dark"] .darkonly-item .map-icon { visibility: visible !important; opacity: 1 !important; }
  [data-theme="light"] .lightonly-item img, [data-theme="light"] .lightonly-item .map-icon { visibility: visible !important; opacity: 1 !important; }
</style>
```

### Current Status (2026-03-24)
- **No flicker on initial load**: Using `visibility: inherit` and `opacity: 1 !important` to respect body's visibility
- **Theme toggling NOT working**: Images don't show when toggling - likely ScrollReveal inline styles overriding CSS
- **SCSS (assets/scss/_custom.scss)**: No lightonly/darkonly rules remain - all handled in head.html inline

## Issues Encountered

1. **Flicker on initial page load**: Images appeared before header/body content
   - Root cause: CSS set `visibility: visible` and `opacity: 1` on images, overriding body's `visibility: hidden`
   - Fix: Use `visibility: inherit` to respect body's visibility

2. **Images don't show when toggling themes**: After toggling, darkonly images show empty space
   - Root cause: ScrollReveal adds inline `style="opacity: 0; transform: ..."` to images
   - Need to find a way to override this when theme changes without causing initial flicker

3. **Theme is applied via JS**: The `data-theme` attribute is set by JavaScript, not server-side

## Approaches to Try

### Approach 1: Use CSS only (current)
- Pros: No JS overhead
- Cons: Hard to toggle visibility when ScrollReveal has inline styles

### Approach 2: Add JS to toggle visibility on theme change
```javascript
function updateLightDarkOnlyItems(theme) {
  var lightonlyItems = document.querySelectorAll(".lightonly-item");
  var darkonlyItems = document.querySelectorAll(".darkonly-item");
  
  lightonlyItems.forEach(function(item) {
    item.style.display = theme === "dark" ? "none" : "list-item";
    // Also toggle visibility on images inside
    var images = item.querySelectorAll('img');
    images.forEach(function(img) {
      img.style.visibility = theme === "light" ? "visible" : "hidden";
    });
  });
  
  darkonlyItems.forEach(function(item) {
    item.style.display = theme === "dark" ? "list-item" : "none";
    var images = item.querySelectorAll('img');
    images.forEach(function(img) {
      img.style.visibility = theme === "dark" ? "visible" : "hidden";
    });
  });
}
```
- Problem: This was causing loading delay because it runs on DOMContentLoaded

### Approach 3: Use CSS custom properties
Instead of toggling display, use CSS custom properties that theme JS can set:
```css
:root {
  --lightonly-display: list-item;
  --darkonly-display: none;
}
[data-theme="dark"] {
  --lightonly-display: none;
  --darkonly-display: list-item;
}
.lightonly-item { display: var(--lightonly-display) !important; }
.darkonly-item { display: var(--darkonly-display) !important; }
```

Then in theme JS:
```javascript
document.documentElement.style.setProperty('--lightonly-display', 'none');
```

### Approach 4: Make ScrollReveal skip these elements
Configure ScrollReveal to ignore elements with lightonly/darkonly class.

### Approach 5: Use data-theme attribute on body instead of html
Maybe adding the theme to body would help with inheritance?

## Files to Modify
- `_includes/head.html` - CSS rules (inline)
- `_includes/item-gallery.html` - Adds CSS classes
- `_layouts/item.html` - Body visibility handling

## Testing Checklist
- [ ] Page loads without images appearing before header
- [ ] Light mode: lightonly images visible, darkonly hidden
- [ ] Dark mode: darkonly images visible, lightonly hidden
- [ ] Toggling theme updates visibility immediately
- [ ] Lightbox works for all images regardless of lightonly/darkonly
- [ ] Map icons work correctly
