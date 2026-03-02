#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="${DARKIFY_CONFIG_FILE:-"$ROOT_DIR/_config.yml"}"
THUMBS_CONFIG_FILE="${DARKIFY_TEST_THUMBS_CONFIG_FILE:-"$SCRIPT_DIR/levels.yml"}"
INPUT_DIR="${1:-"$SCRIPT_DIR/input"}"
OUTPUT_DIR="${2:-"$SCRIPT_DIR/output-thumbnails"}"

config_value_from_file() {
  local file="$1"
  local path="$2"
  if [ -f "$file" ] && command -v yq >/dev/null 2>&1; then
    yq -r "$path // \"\"" "$file"
  else
    echo ""
  fi
}

# Levels precedence:
# 1) Env vars
# 2) scripts/darkify-test/levels.yml (or DARKIFY_TEST_THUMBS_CONFIG_FILE)
# 3) _config.yml (darkify.invert_level.*)
# 4) hardcoded fallbacks
CFG_MAIN_DARKIFY_INVERT_LEVEL_DEFAULT="$(config_value_from_file "$CONFIG_FILE" '.darkify.invert_level.default')"
CFG_MAIN_DARKIFY_INVERT_LEVEL_SMALL="$(config_value_from_file "$CONFIG_FILE" '.darkify.invert_level.small')"
CFG_MAIN_DARKIFY_INVERT_LEVEL_MEDIUM="$(config_value_from_file "$CONFIG_FILE" '.darkify.invert_level.medium')"
CFG_MAIN_DARKIFY_INVERT_LEVEL_LARGE="$(config_value_from_file "$CONFIG_FILE" '.darkify.invert_level.large')"

CFG_TEST_DARKIFY_INVERT_LEVEL_DEFAULT="$(config_value_from_file "$THUMBS_CONFIG_FILE" '.invert_level.default')"
CFG_TEST_DARKIFY_INVERT_LEVEL_SMALL="$(config_value_from_file "$THUMBS_CONFIG_FILE" '.invert_level.small')"
CFG_TEST_DARKIFY_INVERT_LEVEL_MEDIUM="$(config_value_from_file "$THUMBS_CONFIG_FILE" '.invert_level.medium')"
CFG_TEST_DARKIFY_INVERT_LEVEL_LARGE="$(config_value_from_file "$THUMBS_CONFIG_FILE" '.invert_level.large')"

DARKIFY_INVERT_LEVEL_DEFAULT="${DARKIFY_INVERT_LEVEL_DEFAULT:-${CFG_TEST_DARKIFY_INVERT_LEVEL_DEFAULT:-${CFG_MAIN_DARKIFY_INVERT_LEVEL_DEFAULT:-5%,95%}}}"
DARKIFY_INVERT_LEVEL_SMALL="${DARKIFY_INVERT_LEVEL_SMALL:-${CFG_TEST_DARKIFY_INVERT_LEVEL_SMALL:-${CFG_MAIN_DARKIFY_INVERT_LEVEL_SMALL:-2%,82%}}}"
DARKIFY_INVERT_LEVEL_MEDIUM="${DARKIFY_INVERT_LEVEL_MEDIUM:-${CFG_TEST_DARKIFY_INVERT_LEVEL_MEDIUM:-${CFG_MAIN_DARKIFY_INVERT_LEVEL_MEDIUM:-3%,88%}}}"
DARKIFY_INVERT_LEVEL_LARGE="${DARKIFY_INVERT_LEVEL_LARGE:-${CFG_TEST_DARKIFY_INVERT_LEVEL_LARGE:-${CFG_MAIN_DARKIFY_INVERT_LEVEL_LARGE:-4%,92%}}}"

ensure_tools() {
  if ! command -v vips >/dev/null 2>&1; then
    echo "vips not found in PATH."
    echo "Install libvips and run again."
    exit 1
  fi

  if command -v magick >/dev/null 2>&1; then
    IM_CMD="magick"
  elif command -v convert >/dev/null 2>&1; then
    IM_CMD="convert"
  else
    echo "ImageMagick not found in PATH (expected 'magick' or 'convert')."
    exit 1
  fi
}

darkify_invert_lightness() {
  local src="$1"
  local dest="$2"
  local level="$3"

  "$IM_CMD" "$src" \
    -colorspace HSL \
    -channel Lightness -negate \
    -channel RGB \
    -colorspace sRGB \
    -level "$level" \
    "$dest"
}

ensure_tools
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

mapfile -t INPUT_FILES < <(find "$INPUT_DIR" -maxdepth 1 -type f \
  \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
  | sort)

if [ "${#INPUT_FILES[@]}" -eq 0 ]; then
  echo "No input images found in: $INPUT_DIR"
  echo "Add one or two images, then rerun."
  exit 0
fi

for src in "${INPUT_FILES[@]}"; do
  filename="$(basename "$src")"
  base="${filename%.*}"
  ext="${filename##*.}"
  target_dir="$OUTPUT_DIR/$base"
  mkdir -p "$target_dir"

  orig_width="$(vipsheader -f width "$src")"
  orig_height="$(vipsheader -f height "$src")"
  aspect_ratio="$(awk "BEGIN {printf \"%.3f\", $orig_width / $orig_height}")"

  if [ "$(awk "BEGIN {print ($aspect_ratio <= 0.8)}")" -eq 1 ]; then
    small_size=565
    medium_size=1131
    large_size=2263
    size_profile="tall"
  else
    small_size=400
    medium_size=800
    large_size=1600
    size_profile="square-wide"
  fi

  echo "Generating thumbnail darkify test set for: $filename ($size_profile profile)"

  cp "$src" "$target_dir/original.$ext"
  darkify_invert_lightness "$target_dir/original.$ext" "$target_dir/original-dark.$ext" "$DARKIFY_INVERT_LEVEL_DEFAULT"

  vips thumbnail "$src" "$target_dir/small.webp[Q=95,near_lossless=true]" "$small_size" --intent relative
  vips thumbnail "$src" "$target_dir/medium.webp[Q=95,near_lossless=true]" "$medium_size" --intent relative
  vips thumbnail "$src" "$target_dir/large.webp[Q=95,near_lossless=true]" "$large_size" --intent relative

  darkify_invert_lightness "$target_dir/small.webp" "$target_dir/small-dark.webp" "$DARKIFY_INVERT_LEVEL_SMALL"
  darkify_invert_lightness "$target_dir/medium.webp" "$target_dir/medium-dark.webp" "$DARKIFY_INVERT_LEVEL_MEDIUM"
  darkify_invert_lightness "$target_dir/large.webp" "$target_dir/large-dark.webp" "$DARKIFY_INVERT_LEVEL_LARGE"

  cat > "$target_dir/levels.txt" <<EOF
default=$DARKIFY_INVERT_LEVEL_DEFAULT
small=$DARKIFY_INVERT_LEVEL_SMALL
medium=$DARKIFY_INVERT_LEVEL_MEDIUM
large=$DARKIFY_INVERT_LEVEL_LARGE
EOF
  if [ -f "$THUMBS_CONFIG_FILE" ]; then
    cp "$THUMBS_CONFIG_FILE" "$target_dir/levels-config.yml"
  fi

  echo "  - wrote: $target_dir/original.$ext"
  echo "  - wrote: $target_dir/original-dark.$ext"
  echo "  - wrote: $target_dir/{small,medium,large}.webp"
  echo "  - wrote: $target_dir/{small,medium,large}-dark.webp"
  if [ -f "$THUMBS_CONFIG_FILE" ]; then
    echo "  - wrote: $target_dir/levels-config.yml"
  fi
done

echo ""
echo "Done. Compare outputs in: $OUTPUT_DIR"
echo "Levels source priority:"
echo "  env vars > $THUMBS_CONFIG_FILE > $CONFIG_FILE > built-in defaults"
echo "Tip: edit $THUMBS_CONFIG_FILE and rerun."
