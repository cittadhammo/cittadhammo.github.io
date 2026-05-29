# Darkify Test

Quick local test harness for the darkify methods used by `scripts/generate_assets.sh`.

Default invert-lightness levels are read from `scripts/darkify-test/levels.yml` first, then `_config.yml`:
- `darkify.invert_level.default`
- `darkify.invert_level.small`
- `darkify.invert_level.medium`
- `darkify.invert_level.large`

## Usage

1. Put one or more test images in:
   - `scripts/darkify-test/input/`
2. Run:

```bash
bash scripts/darkify-test/run.sh
# or
make darkify-test
```

Optional custom dirs:

```bash
bash scripts/darkify-test/run.sh /path/to/input /path/to/output
# or
make darkify-test DARKIFY_TEST_INPUT=/path/to/input DARKIFY_TEST_OUTPUT=/path/to/output
```

## Interactive TUI (Recommended for tuning)

Use the interactive TUI to pick an image, tune levels for each size, and iterate quickly:

```bash
make darkify-tui
```

Features:
- **Image Selection**: Choose from `scripts/darkify-test/input/`.
- **Parameter Tuning**: Live-edit `invert_lightness` levels (or choose other methods).
- **Size-Aware**: Automatically applies correct thumbnail dimensions (tall vs square-wide profiles).
- **Iteration History**: Save results to custom folders with a label (e.g. `test1`, `v2`).
- **Config Sync**: Optionally save your best settings back to `scripts/darkify-test/levels.yml`.

## Thumbnail-Specific Test (Legacy manual flow)

Use this to test the production thumbnail flow with per-size `invert_lightness` levels:

```bash
bash scripts/darkify-test/run-thumbnails.sh
# or
make darkify-test-thumbnails
```

Optional custom dirs:

```bash
bash scripts/darkify-test/run-thumbnails.sh /path/to/input /path/to/output-thumbnails
# or
make darkify-test-thumbnails DARKIFY_TEST_INPUT=/path/to/input DARKIFY_THUMBS_OUTPUT=/path/to/output-thumbnails
```

Optional level overrides for quick tuning:

```bash
DARKIFY_INVERT_LEVEL_DEFAULT='5%,95%' DARKIFY_INVERT_LEVEL_SMALL='1%,78%' DARKIFY_INVERT_LEVEL_MEDIUM='2%,85%' DARKIFY_INVERT_LEVEL_LARGE='3%,90%' bash scripts/darkify-test/run-thumbnails.sh
# or
make darkify-test-thumbnails DARKIFY_INVERT_LEVEL_DEFAULT='5%,95%' DARKIFY_INVERT_LEVEL_SMALL='1%,78%' DARKIFY_INVERT_LEVEL_MEDIUM='2%,85%' DARKIFY_INVERT_LEVEL_LARGE='3%,90%'
```

Edit local thumbnail test config (recommended workflow):

```yaml
# scripts/darkify-test/levels.yml
invert_level:
  default: "5%,95%"
  small: "2%,82%"
  medium: "3%,88%"
  large: "4%,92%"
```

Then run:

```bash
make darkify-test-thumbnails
```

Use another thumbnail levels file (optional):

```bash
make darkify-test-thumbnails DARKIFY_THUMBS_CONFIG_FILE=/path/to/levels.yml
```

Use another config file (optional):

```bash
make darkify-test DARKIFY_CONFIG_FILE=/path/to/_config.yml
make darkify-test-thumbnails DARKIFY_CONFIG_FILE=/path/to/_config.yml
- **Config Sync**: Optionally save your best settings back to `scripts/darkify-test/levels.yml`.
- **Optional Large Thumbnails**: Large thumbnail generation is disabled by default to speed up iteration, but can be enabled on-demand.

## Tuning Guide (invert_lightness)

The `invert_lightness` method uses a `-level black%,white%` adjustment. The default **5%,95%** is a balanced starting point for Dhamma charts.

### Why 5% and 95%?
*   **Highlight/Shadow Recovery**: Most "white" backgrounds in scans aren't pure white (e.g., 98%). Setting the white clip to **95%** forces these near-whites to pure white before inversion, ensuring a clean dark background without "haze."
*   **Noise Reduction**: Setting the black clip to **5%** ensures near-black ink/strokes are solid before inversion, preventing "muddy" or washed-out text in dark mode.
*   **Contrast Stretching**: By pulling the limits in, you stretch the middle 90% of color data across the full 100% range, making lines look sharper and colors more vibrant.

### When to adjust?
*   **Lower the Black (e.g., 2%)**: If very fine, subtle gray details are disappearing.
*   **Lower the White (e.g., 85%)**: If the source has a very "dirty" or yellowed background (like an old scan) that isn't turning fully dark.
*   **Higher the White (e.g., 98%)**: If bright colors look like "glowing neon" or details in highlights are being "blown out."

## Output

### TUI Results
Written to `scripts/darkify-test/output-tui/<image-base>_<label>_<timestamp>/`:
- `original.<ext>`, `original-dark.<ext>`
- `small.webp`, `small-dark.webp`
- `medium.webp`, `medium-dark.webp`
- `large.webp`, `large-dark.webp` (only if enabled)
- `settings.txt`: Records method and levels used for that specific iteration.

### Legacy Method Comparison
Written to `scripts/darkify-test/output/<image-base>/`:
- `original.<ext>`
- `<image-base>-replace.<ext>`
- `<image-base>-multiply.<ext>`
- `<image-base>-invert_lightness.<ext>`
- `<image-base>-replace_only.<ext>`

### Legacy Thumbnail Test
Written to `scripts/darkify-test/output-thumbnails/<image-base>/`:
- `original.<ext>`, `original-dark.<ext>`
- `small.webp`, `medium.webp`, `large.webp`
- `small-dark.webp`, `medium-dark.webp`, `large-dark.webp`
- `levels.txt` (records the exact level settings used)
- `levels-config.yml` (copy of the thumbnail test config file used for that run, if present)

## Notes

- Requires ImageMagick (`magick` in PATH), `libvips` (`vips` in PATH), and `gum`.
- Supported inputs: `.png`, `.jpg`, `.jpeg`, `.webp`.

