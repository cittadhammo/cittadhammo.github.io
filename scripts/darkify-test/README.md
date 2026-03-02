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

## Thumbnail-Specific Test (new)

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
```

## Output

For each input image, results are written to:
- `scripts/darkify-test/output/<image-base>/`

Files generated:
- `original.<ext>`
- `<image-base>-replace.<ext>`
- `<image-base>-multiply.<ext>`
- `<image-base>-invert_lightness.<ext>`
- `<image-base>-replace_only.<ext>`

For thumbnail-specific tests, results are written to:
- `scripts/darkify-test/output-thumbnails/<image-base>/`

Files generated:
- `original.<ext>`, `original-dark.<ext>`
- `small.webp`, `medium.webp`, `large.webp`
- `small-dark.webp`, `medium-dark.webp`, `large-dark.webp`
- `levels.txt` (records the exact level settings used)
- `levels-config.yml` (copy of the thumbnail test config file used for that run, if present)

## Notes

- Requires ImageMagick (`magick` in PATH).
- Supported inputs: `.png`, `.jpg`, `.jpeg`, `.webp`.
