# Darkify Test

Quick local test harness for the darkify methods used by `scripts/generate_assets.sh`.

## Usage

1. Put one or more test images in:
   - `scripts/darkify-test/input/`
2. Run:

```bash
bash scripts/darkify-test/run.sh
```

Optional custom dirs:

```bash
bash scripts/darkify-test/run.sh /path/to/input /path/to/output
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

## Notes

- Requires ImageMagick (`magick` in PATH).
- Supported inputs: `.png`, `.jpg`, `.jpeg`, `.webp`.
