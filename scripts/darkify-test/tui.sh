#!/usr/bin/env bash
set -euo pipefail

# Darkify TUI - A tuning harness for Dhamma Charts darkify parameters
# Requires: gum, vips, ImageMagick

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
INPUT_DIR="$SCRIPT_DIR/input"
OUTPUT_BASE_DIR="$SCRIPT_DIR/output-tui"
LEVELS_CONFIG="$SCRIPT_DIR/levels.yml"

# Ensure tools are present
for tool in gum vips magick yq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: $tool is not installed."
        exit 1
    fi
done

mkdir -p "$INPUT_DIR" "$OUTPUT_BASE_DIR"

# Helper to read from levels.yml
get_level() {
    local key="$1"
    if [[ -f "$LEVELS_CONFIG" ]]; then
        yq -r ".invert_level.$key // \"\"" "$LEVELS_CONFIG"
    else
        echo ""
    fi
}

# Initialize levels from config or defaults
DEFAULT_LEVEL=$(get_level "default")
[[ -z "$DEFAULT_LEVEL" ]] && DEFAULT_LEVEL="5%,95%"
SMALL_LEVEL=$(get_level "small")
[[ -z "$SMALL_LEVEL" ]] && SMALL_LEVEL="2%,82%"
MEDIUM_LEVEL=$(get_level "medium")
[[ -z "$MEDIUM_LEVEL" ]] && MEDIUM_LEVEL="3%,88%"
LARGE_LEVEL=$(get_level "large")
[[ -z "$LARGE_LEVEL" ]] && LARGE_LEVEL="4%,92%"

# Helper to get level as numbers
get_level_parts() {
    local val="$1"
    local default_black="$2"
    local default_white="$3"
    if [[ "$val" =~ ([0-9]+)%,([0-9]+)% ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        echo "$default_black $default_white"
    fi
}

# Helper to input level parts
input_level() {
    local header="$1"
    local current_val="$2"
    read -r b w < <(get_level_parts "$current_val" 5 95)
    
    local new_b=$(gum input --placeholder "Black point % (shadow clip)" --value "$b" --header "$header - Black (Shadows):")
    local new_w=$(gum input --placeholder "White point % (highlight clip)" --value "$w" --header "$header - White (Highlights):")
    
    echo "${new_b}%,${new_w}%"
}

darkify_invert_lightness() {
    local src="$1"
    local dest="$2"
    local level="$3"
    magick "$src" -colorspace HSL -channel Lightness -negate -channel RGB -colorspace sRGB -level "$level" "$dest"
}

darkify_replace() {
    local src="$1"
    local dest="$2"
    magick "$src" -modulate 100,110,100 -fuzz 15% -fill "#121212" -opaque "#ffffff" -fuzz 15% -fill "#e6e6e6" -opaque "#000000" "$dest"
}

darkify_multiply() {
    local src="$1"
    local dest="$2"
    magick "$src" \( +clone -colorspace gray -threshold 90% -negate \) -compose Multiply -composite -brightness-contrast -5x20 "$dest"
}

darkify_replace_only() {
    local src="$1"
    local dest="$2"
    magick "$src" -fuzz 10% -fill "#121212" -opaque white -fuzz 10% -fill "#e6e6e6" -opaque black "$dest"
}

while true; do
    # 1. Select Image
    IMAGES=$(find "$INPUT_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf "%f\n" | sort)

    if [[ -z "$IMAGES" ]]; then
        gum style --foreground 196 "No images found in $INPUT_DIR"
        exit 1
    fi

    SELECTED_IMAGE=$(echo "$IMAGES" | gum choose --header "Select an image to tune (or press ESC to exit):")
    [[ -z "$SELECTED_IMAGE" ]] && break

    IMAGE_PATH="$INPUT_DIR/$SELECTED_IMAGE"
    IMAGE_BASE="${SELECTED_IMAGE%.*}"
    IMAGE_EXT="${SELECTED_IMAGE##*.}"

    gum style --border normal --padding "0 1" --margin "1 0" --foreground 212 "Tuning: $SELECTED_IMAGE"

    # 2. Choose Method
    METHOD=$(gum choose "invert_lightness" "replace" "multiply" "replace_only")

    # 3. Prepare iteration
    ITERATION_DIR="$OUTPUT_BASE_DIR/tmp_current"
    rm -rf "$ITERATION_DIR" && mkdir -p "$ITERATION_DIR"
    cp "$IMAGE_PATH" "$ITERATION_DIR/original.$IMAGE_EXT"

    # Size logic
    orig_width="$(vipsheader -f width "$IMAGE_PATH")"
    orig_height="$(vipsheader -f height "$IMAGE_PATH")"
    aspect_ratio="$(awk "BEGIN {printf \"%.3f\", $orig_width / $orig_height}")"
    if [ "$(awk "BEGIN {print ($aspect_ratio <= 0.8)}")" -eq 1 ]; then
        small_size=565; medium_size=1131; large_size=2263; size_profile="tall"
    else
        small_size=400; medium_size=800; large_size=1600; size_profile="square-wide"
    fi

    tune_size() {
        local size_label="$1"
        local src="$2"
        local dest_base="$3"
        local current_level_var="$4"
        local level="${!current_level_var}"

        while true; do
            if [[ "$METHOD" == "invert_lightness" ]]; then
                level=$(input_level "Tune $size_label" "$level")
                eval "$current_level_var='$level'"
            fi

            echo "Processing $size_label..."
            case "$METHOD" in
                invert_lightness) darkify_invert_lightness "$src" "${dest_base}-dark.${src##*.}" "$level" ;;
                replace)          darkify_replace          "$src" "${dest_base}-dark.${src##*.}" ;;
                multiply)         darkify_multiply         "$src" "${dest_base}-dark.${src##*.}" ;;
                replace_only)     darkify_replace_only     "$src" "${dest_base}-dark.${src##*.}" ;;
            esac

            # Show result
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "${dest_base}-dark.${src##*.}" &>/dev/null &
            fi

            gum style --foreground 212 "Current $size_label level: $level"
            local action=$(gum choose "Looks Good (Next Size)" "Tweak $size_label Again" "Discard this Image")
            
            [[ "$action" == "Looks Good (Next Size)" ]] && return 0
            [[ "$action" == "Discard this Image" ]] && return 1
            # "Tweak Again" continues the loop
        done
    }

    # Step-by-step tuning
    tune_size "Original" "$ITERATION_DIR/original.$IMAGE_EXT" "$ITERATION_DIR/original" DEFAULT_LEVEL || continue
    
    echo "Generating Small thumbnail..."
    vips thumbnail "$IMAGE_PATH" "$ITERATION_DIR/small.webp[Q=95,near_lossless=true]" "$small_size" --intent relative
    tune_size "Small" "$ITERATION_DIR/small.webp" "$ITERATION_DIR/small" SMALL_LEVEL || continue

    echo "Generating Medium thumbnail..."
    vips thumbnail "$IMAGE_PATH" "$ITERATION_DIR/medium.webp[Q=95,near_lossless=true]" "$medium_size" --intent relative
    tune_size "Medium" "$ITERATION_DIR/medium.webp" "$ITERATION_DIR/medium" MEDIUM_LEVEL || continue

    GEN_LARGE=$(gum confirm "Generate Large Thumbnail?" --default=false && echo "yes" || echo "no")
    if [[ "$GEN_LARGE" == "yes" ]]; then
        echo "Generating Large thumbnail..."
        vips thumbnail "$IMAGE_PATH" "$ITERATION_DIR/large.webp[Q=95,near_lossless=true]" "$large_size" --intent relative
        tune_size "Large" "$ITERATION_DIR/large.webp" "$ITERATION_DIR/large" LARGE_LEVEL || continue
    fi

    # Save settings used (YAML format for easy copy-paste)
    cat > "$ITERATION_DIR/settings.txt" <<EOF
# Method: $METHOD
    invert_level:
      default: "$DEFAULT_LEVEL"
      small: "$SMALL_LEVEL"
      medium: "$MEDIUM_LEVEL"
EOF
    [[ "$GEN_LARGE" == "yes" ]] && echo "      large: \"$LARGE_LEVEL\"" >> "$ITERATION_DIR/settings.txt"

    gum style --foreground 46 "All sizes tuned for $SELECTED_IMAGE!"
    
    # 5. Action Choice
    CHOICE=$(gum choose "Save & Tune Another Image" "Save & Exit" "Discard & Exit")

    if [[ "$CHOICE" == *"Save"* ]]; then
        LABEL=$(gum input --placeholder "Enter a label for this iteration" --header "Iteration Label:")
        FINAL_DIR="$OUTPUT_BASE_DIR/${IMAGE_BASE}_${LABEL}_$(date +%H%M%S)"
        mv "$ITERATION_DIR" "$FINAL_DIR"
        gum style --foreground 212 "Iteration saved to: $FINAL_DIR"
        
        if [[ "$METHOD" == "invert_lightness" ]]; then
            if gum confirm "Update levels.yml with these settings?"; then
                cat > "$LEVELS_CONFIG" <<EOF
invert_level:
  default: "$DEFAULT_LEVEL"
  small: "$SMALL_LEVEL"
  medium: "$MEDIUM_LEVEL"
  large: "$LARGE_LEVEL"
EOF
                gum style --foreground 46 "Updated $LEVELS_CONFIG"
            fi
        fi
    fi

    if [[ "$CHOICE" == *"Exit"* ]]; then
        break
    fi
done

gum style --foreground 212 "Done!"
