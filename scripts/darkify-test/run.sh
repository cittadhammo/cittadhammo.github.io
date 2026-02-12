#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${1:-"$SCRIPT_DIR/input"}"
OUTPUT_DIR="${2:-"$SCRIPT_DIR/output"}"

# TUNING CHEAT SHEET (ImageMagick arguments used in this file)
# -brightness-contrast A x B
#   - A (brightness): negative = darker, positive = brighter.
#   - B (contrast): negative = flatter/washed, positive = punchier.
#   - Current `-5x20` means "darken a bit, then boost contrast."
#   - Practical tweak range for this workflow:
#     - A: -20..+20 (step 2-5)
#     - B: 0..40 (step 5)
# -threshold P%
#   - Converts gray to black/white at cutoff P.
#   - Lower P => more pixels considered "bright" before negate => more darkening after multiply.
#   - Higher P => only very bright pixels affected.
#   - Practical range: 70..98 (step 2-5).
# -fuzz P%
#   - Color match tolerance for `-opaque` replacement.
#   - Lower P => strict match (fewer pixels replaced), higher P => broader replacement.
#   - Practical range: 2..25 (step 2-3).
# -level black%,white%
#   - black%: values at/below this become black (shadow clip point).
#   - white%: values at/above this become white (highlight clip point).
#   - Smaller gap (e.g. 10,90) = stronger contrast/stretch.
#   - Safer range: black 0..15, white 85..100.
# -modulate B,S,H
#   - B brightness %, S saturation %, H hue %.
#   - 100 means "no change"; S>100 adds saturation.
#   - Keep H near 100 unless you explicitly want hue shift.
#
# Methods available for side-by-side output comparison.
# - replace: color-aware remap of near-white/near-black tones after mild saturation lift.
# - multiply: builds a mask from highlights and darkens using Multiply blend.
# - invert_lightness: flips only HSL lightness so hues stay closer to source.
# - replace_only: simplest hard swap of white/black without extra tone shaping.
METHODS=("replace" "multiply" "invert_lightness" "replace_only")

ensure_magick() {
  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick 'magick' not found in PATH."
    echo "Install ImageMagick, then run this script again."
    exit 1
  fi
}

darkify_image() {
  local src="$1"
  local dest="$2"
  local method="$3"

  case "$method" in
    replace)
      # Method: replace
      # Good for diagrams with near-white background + near-black strokes.
      # Full pipeline details (left to right):
      # 1) `"$src"`: read input image.
      # 2) `-modulate 100,110,100`:
      #    - first `100` = brightness (100% = unchanged),
      #    - second `110` = saturation (110% = +10% saturation),
      #    - third `100` = hue (100% = unchanged hue rotation baseline).
      #    Tweaks:
      #    - `100,100,100` = disable saturation boost.
      #    - `100,120,100` = more color separation before replacement.
      #    - keep 3rd value at `100` unless intentionally shifting hues.
      # 3) `-fuzz 15%`: set color-match tolerance for next `-opaque`.
      #    Pixels within 15% distance of target color are considered matches.
      #    Lower to `8-12%` if too many colored pixels get replaced.
      #    Raise to `18-22%` if off-white background is not fully captured.
      # 4) `-fill "#121212"`: replacement color used by next paint op.
      # 5) `-opaque "#ffffff"`: replace matching near-white pixels with fill.
      # 6) `-fuzz 15%`: reset same tolerance for black replacement pass.
      # 7) `-fill "#e6e6e6"`: light foreground color for dark mode.
      # 8) `-opaque "#000000"`: replace matching near-black pixels with fill.
      # 9) `"$dest"`: write output image path.
      magick "$src" \
        -modulate 100,110,100 \
        -fuzz 15% -fill "#121212" -opaque "#ffffff" \
        -fuzz 15% -fill "#e6e6e6" -opaque "#000000" \
        "$dest"
      ;;
    multiply)
      # Method: multiply
      # Better when the source has gradients/anti-aliased edges.
      # Full pipeline details:
      # 1) `"$src"`: read base image (image list index 0).
      # 2) `\( ... \)`: open a grouped sub-expression on a clone stream.
      # 3) `+clone`: duplicate current image (creates image list index 1).
      # 4) `-colorspace gray`: convert clone to grayscale luminance.
      # 5) `-threshold 90%`: binarize clone; >=90% -> white, else black.
      #    Lower threshold (e.g. 80) => more of image gets darkened later.
      #    Higher threshold (e.g. 95) => only brightest regions get darkened.
      # 6) `-negate`: invert mask so bright areas become darkening contributors.
      # 7) `\)`: close grouped operations; keep original + processed clone.
      # 8) `-compose Multiply`: choose multiply blend mode for compositing.
      # 9) `-composite`: blend top image (mask clone) onto base original.
      # 10) `-brightness-contrast -5x20`:
      #    - first value `-5` (A) darkens a bit.
      #      Try A in `-15..0` for dark mode charts.
      #    - second value `20` (B) adds contrast/separation.
      #      Try B in `10..35`:
      #      - lower B if lines look harsh/noisy,
      #      - higher B if image looks muddy/flat.
      # 11) `"$dest"`: write final output.
      magick "$src" \
        \( +clone -colorspace gray -threshold 90% -negate \) \
        -compose Multiply -composite \
        -brightness-contrast -5x20 \
        "$dest"
      ;;
    invert_lightness)
      # Method: invert_lightness
      # Invert tone while trying to preserve perceived hue/chroma relations.
      # Full pipeline details:
      # 1) `"$src"`: read input.
      # 2) `-colorspace HSL`: convert pixel representation to HSL channels.
      # 3) `-channel Lightness -negate`: invert only the Lightness channel.
      # 4) `-channel RGB`: reset active channel mask back to all color channels.
      #    (In IM, this means "operate on all standard color channels".)
      # 5) `-colorspace sRGB`: convert back to standard display color space.
      # 6) `-brightness-contrast -5x20`: darken slightly + add contrast.
      #    Same geometry as above: A x B = brightness x contrast.
      #    Good start values:
      #    - subtle: `-2x10`
      #    - current: `-5x20`
      #    - stronger: `-10x30`
      # 7) `-level 5%,95%`: remap tones:
      #    - input 5% becomes output black,
      #    - input 95% becomes output white,
      #    - values in-between are stretched.
      #    Tweaks:
      #    - `3%,97%` = gentler clipping (more source tone preserved).
      #    - `8%,92%` = stronger clipping (more contrast, less subtle gradient detail).
      # 8) `"$dest"`: write output.
      magick "$src" \
        -colorspace HSL \
        -channel Lightness -negate \
        -channel RGB \
        -colorspace sRGB \
        -brightness-contrast -5x20 \
        -level 5%,95% \
        "$dest"
      ;;
    replace_only)
      # Method: replace_only
      # Minimal direct color swap, no contrast/saturation pre/post adjustments.
      # Full pipeline details:
      # 1) `"$src"`: read input.
      # 2) `-fuzz 10%`: tolerance for near-white matching (stricter than 15%).
      #    Try 5-8% for strict line-art; 12-18% for uneven scans/photos.
      # 3) `-fill "#121212"`: dark replacement color.
      # 4) `-opaque white`: replace white-ish pixels with fill color.
      # 5) `-fuzz 10%`: tolerance for near-black matching.
      #    Increase if near-black strokes are not being converted.
      # 6) `-fill "#e6e6e6"`: light replacement color.
      # 7) `-opaque black`: replace black-ish pixels with fill color.
      # 8) `"$dest"`: write output.
      magick "$src" \
        -fuzz 10% -fill "#121212" -opaque white \
        -fuzz 10% -fill "#e6e6e6" -opaque black \
        "$dest"
      ;;
    *)
      echo "Unknown darkify method: $method"
      exit 1
      ;;
  esac
}

ensure_magick
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

mapfile -t INPUT_FILES < <(find "$INPUT_DIR" -maxdepth 1 -type f \
  \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
  | sort)

if [ "${#INPUT_FILES[@]}" -eq 0 ]; then
  echo "No input images found in: $INPUT_DIR"
  echo "Add image files (.png/.jpg/.jpeg/.webp), then rerun."
  exit 0
fi

for src in "${INPUT_FILES[@]}"; do
  filename="$(basename "$src")"
  base="${filename%.*}"
  ext="${filename##*.}"
  target_dir="$OUTPUT_DIR/$base"

  mkdir -p "$target_dir"
  cp "$src" "$target_dir/original.$ext"

  echo "Testing darkify methods for: $filename"
  for method in "${METHODS[@]}"; do
    out="$target_dir/${base}-${method}.${ext}"
    darkify_image "$src" "$out" "$method"
    echo "  - wrote: $out"
  done
done

echo ""
echo "Done. Compare outputs in: $OUTPUT_DIR"
