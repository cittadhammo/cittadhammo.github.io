# Image Optimization Recommendations for Dhammacharts

This document outlines strategic recommendations for optimizing image delivery on slow networks (e.g., 1mb/s) while maintaining high legibility for Dhamma charts and diagrams.

## 1. Format: Transitioning to AVIF
While WebP is excellent for compatibility, **AVIF** is the current "best" format for the type of content found on Dhammacharts (diagrams with text and flat colors).

- **Benefit:** AVIF typically achieves 20-30% better compression than WebP for the same visual quality. For text-heavy charts, it maintains sharper edges with fewer "ringing" artifacts.
- **Implementation:** Keep WebP as a fallback, but generate AVIF versions for modern browsers.
- **Trade-off:** AVIF encoding is CPU-intensive and will increase the time taken by `make assets`.

## 2. Refining Quality Settings (WebP)
The current quality settings (`Q=82` to `Q=88`) are slightly conservative. For diagrams and charts, you can often push compression further without losing legibility.

- **Recommendation:** Lower Quality to **Q=75 or Q=80** for Medium and Large thumbnails. 
- **Impact:** This could reduce the "Medium" file sizes (currently 80-160KB) down to 60-120KB, making them feel much faster on 1mb/s mobile connections.

## 3. Responsive Strategy (The "Mobile-First" Lightbox)
As implemented in our recent fix, using the **Medium (800px)** thumbnail for the default lightbox view is the best balance for mobile users.

- **Why 800px?** Modern mobile screens are high-density (Retina/High-DPI). An 800px image perfectly covers a 400px wide screen at 2x density, providing sharp text without the multi-megabyte penalty of the 1600px+ "Large" version.
- **Desktop/Tablet:** On larger screens, the 1600px version is still appropriate, but on mobile, it should be avoided as the primary lightbox asset.

## 4. Technical "Near-Lossless" vs. Lossy
- **Current State:** Using standard lossy WebP.
- **Observation:** If you notice "smearing" around text, the `near_lossless` flag in `libvips` can be used. However, it significantly increases file size.
- **Verdict:** Stick to **lossy** compression for the best performance on slow networks, as readability remains high even at lower quality levels for these charts.

## 5. Summary of Recommended Specs

| Asset Size | Resolution (Width) | Format | Quality | Best Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Small** | 400px | WebP/AVIF | 75 | Grid/Gallery thumbnails |
| **Medium** | 800px | WebP/AVIF | 75 | Mobile Lightbox / Tablet Grid |
| **Large** | 1600px | WebP/AVIF | 80 | Desktop Lightbox / Zoom |
| **Tiles** | 256px | WebP | 85 | High-res Map Viewer (Deep Zoom) |

## 6. Actionable Next Step
In `scripts/generate_assets.sh`, experiment with changing the quality lines to:
```bash
vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/small.webp[Q=75]" $SMALL_SIZE --intent relative
vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/medium.webp[Q=75]" $MEDIUM_SIZE --intent relative
vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/large.webp[Q=80]" $LARGE_SIZE --intent relative
```
