#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${1:-"$SCRIPT_DIR/input"}"
OUTPUT_DIR="${2:-"$SCRIPT_DIR/output"}"

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
      magick "$src" \
        -modulate 100,110,100 \
        -fuzz 15% -fill "#121212" -opaque "#ffffff" \
        -fuzz 15% -fill "#e6e6e6" -opaque "#000000" \
        "$dest"
      ;;
    multiply)
      magick "$src" \
        \( +clone -colorspace gray -threshold 90% -negate \) \
        -compose Multiply -composite \
        -brightness-contrast -5x20 \
        "$dest"
      ;;
    invert_lightness)
      magick "$src" \
        -colorspace HSL \
        -channel Lightness -negate \
        -channel RGB \
        -colorspace sRGB \
        -brightness-contrast -5x15 \
        -level 5%,95% \
        "$dest"
      ;;
    replace_only)
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
