#!/bin/bash

SRC_IMAGE_DIR="./vault/assets/images"
DEST_IMAGE_DIR="./assets/images"
SRC_DOWNLOAD_PDF_DIR="./vault/assets/pdfs"
SRC_DOWNLOAD_SVG_DIR="./vault/assets/svgs"
MD_DIR="./vault/content" 
MAPS_HTML_DIR="./maps"
SIZE_DATA_FILE="./vault/data/size.yml"
TEMPLATE_FILE="./scripts/map-template.html"
MAPS_HTML_ONLY="${MAPS_HTML_ONLY:-false}"
CONFIG_FILE="./_config.yml"
ASSET_META_VERSION="1"

# Darkify config
DARKIFY_METHOD=$(yq -r '.darkify.method // "replace"' "$CONFIG_FILE")
DARKIFY_SUFFIX=$(yq -r '.darkify.suffix // "dark"' "$CONFIG_FILE")
CFG_DARKIFY_INVERT_LEVEL_DEFAULT=$(yq -r '.darkify.invert_level.default // ""' "$CONFIG_FILE")
CFG_DARKIFY_INVERT_LEVEL_SMALL=$(yq -r '.darkify.invert_level.small // ""' "$CONFIG_FILE")
CFG_DARKIFY_INVERT_LEVEL_MEDIUM=$(yq -r '.darkify.invert_level.medium // ""' "$CONFIG_FILE")
CFG_DARKIFY_INVERT_LEVEL_LARGE=$(yq -r '.darkify.invert_level.large // ""' "$CONFIG_FILE")
# Brighter per-size tuning for thumbnail dark variants when method=invert_lightness.
# Format: "<black-point>,<white-point>" for ImageMagick `-level`.
DARKIFY_INVERT_LEVEL_DEFAULT="${DARKIFY_INVERT_LEVEL_DEFAULT:-$CFG_DARKIFY_INVERT_LEVEL_DEFAULT}"
DARKIFY_INVERT_LEVEL_SMALL="${DARKIFY_INVERT_LEVEL_SMALL:-$CFG_DARKIFY_INVERT_LEVEL_SMALL}"
DARKIFY_INVERT_LEVEL_MEDIUM="${DARKIFY_INVERT_LEVEL_MEDIUM:-$CFG_DARKIFY_INVERT_LEVEL_MEDIUM}"
DARKIFY_INVERT_LEVEL_LARGE="${DARKIFY_INVERT_LEVEL_LARGE:-$CFG_DARKIFY_INVERT_LEVEL_LARGE}"
[ -z "$DARKIFY_INVERT_LEVEL_DEFAULT" ] && DARKIFY_INVERT_LEVEL_DEFAULT="5%,95%"
[ -z "$DARKIFY_INVERT_LEVEL_SMALL" ] && DARKIFY_INVERT_LEVEL_SMALL="2%,82%"
[ -z "$DARKIFY_INVERT_LEVEL_MEDIUM" ] && DARKIFY_INVERT_LEVEL_MEDIUM="3%,88%"
[ -z "$DARKIFY_INVERT_LEVEL_LARGE" ] && DARKIFY_INVERT_LEVEL_LARGE="4%,92%"

# Effective per-image values (can be overridden from frontmatter).
ACTIVE_DARKIFY_INVERT_LEVEL_DEFAULT="$DARKIFY_INVERT_LEVEL_DEFAULT"
ACTIVE_DARKIFY_INVERT_LEVEL_SMALL="$DARKIFY_INVERT_LEVEL_SMALL"
ACTIVE_DARKIFY_INVERT_LEVEL_MEDIUM="$DARKIFY_INVERT_LEVEL_MEDIUM"
ACTIVE_DARKIFY_INVERT_LEVEL_LARGE="$DARKIFY_INVERT_LEVEL_LARGE"

MAGICK_AVAILABLE="unknown"
IM_CMD=""
ensure_magick() {
    if [ "$MAGICK_AVAILABLE" = "unknown" ]; then
        if command -v magick >/dev/null 2>&1; then
            IM_CMD="magick"
            MAGICK_AVAILABLE="true"
        elif command -v convert >/dev/null 2>&1; then
            # ImageMagick 6 commonly exposes `convert` instead of `magick`.
            IM_CMD="convert"
            MAGICK_AVAILABLE="true"
        else
            MAGICK_AVAILABLE="false"
        fi
    fi
    if [ "$MAGICK_AVAILABLE" != "true" ]; then
        echo "ImageMagick binary not found in PATH (expected 'magick' or 'convert'). Install ImageMagick to enable darkify."
        exit 1
    fi
}

darkify_image() {
    local src="$1"
    local dest="$2"
    local method="$3"
    local variant="${4:-default}"
    local invert_level="$ACTIVE_DARKIFY_INVERT_LEVEL_DEFAULT"

    if [ "$variant" = "thumb-small" ]; then
        invert_level="$ACTIVE_DARKIFY_INVERT_LEVEL_SMALL"
    elif [ "$variant" = "thumb-medium" ]; then
        invert_level="$ACTIVE_DARKIFY_INVERT_LEVEL_MEDIUM"
    elif [ "$variant" = "thumb-large" ]; then
        invert_level="$ACTIVE_DARKIFY_INVERT_LEVEL_LARGE"
    fi

    case "$method" in
        replace)
            "$IM_CMD" "$src" \
                -modulate 100,110,100 \
                -fuzz 15% -fill "#121212" -opaque "#ffffff" \
                -fuzz 15% -fill "#e6e6e6" -opaque "#000000" \
                "$dest"
            ;;
        multiply)
            "$IM_CMD" "$src" \
                \( +clone -colorspace gray -threshold 90% -negate \) \
                -compose Multiply -composite \
                -brightness-contrast -5x20 \
                "$dest"
            ;;
        invert_lightness)
            "$IM_CMD" "$src" \
                -colorspace HSL \
                -channel Lightness -negate \
                -channel RGB \
                -colorspace sRGB \
                -level "$invert_level" \
                "$dest"
            ;;
        replace_only)
            "$IM_CMD" "$src" \
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

darkify_tile_set() {
    local light_tiles_dir="$1"
    local dark_tiles_dir="$2"
    local method="$3"
    local tile_count=0

    rm -rf "$dark_tiles_dir"
    mkdir -p "$dark_tiles_dir"
    cp -a "$light_tiles_dir"/. "$dark_tiles_dir"/

    while IFS= read -r tile_file; do
        local ext="${tile_file##*.}"
        local base="${tile_file%.*}"
        local temp_file="${base}.tmp.${ext}"
        darkify_image "$tile_file" "$temp_file" "$method"
        mv "$temp_file" "$tile_file"
        tile_count=$((tile_count + 1))
    done < <(find "$dark_tiles_dir" -type f \( -name "*.webp" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | sort)

    echo "Generated $tile_count dark tiles in $dark_tiles_dir"
}

TILE_GENERATION_LOG=""

flatten_if_alpha() {
    local src="$1"
    local bg="$2"
    local tmp_file="$3"
    local bands=""

    bands=$(vipsheader -f bands "$src" 2>/dev/null)

    if [ "$bands" = "4" ]; then
        local r g b
        r=$(echo "$bg" | awk '{print $1}')
        g=$(echo "$bg" | awk '{print $2}')
        b=$(echo "$bg" | awk '{print $3}')
        if vips flatten "$src" "$tmp_file" --background "$r,$g,$b" 2>/dev/null; then
            echo "$tmp_file"
            return 0
        else
            echo "$src"
            return 1
        fi
    else
        echo "$src"
        return 0
    fi
}

generate_tiles() {
    local src="$1"
    local dest="$2"
    local bg="$3"
    local label="$4"
    local result=""
    local suffix_used=""
    local work_src="$src"

    rm -rf "$dest"
    mkdir -p "$dest"

    local tmp_flat=""
    if [ -n "$bg" ]; then
        tmp_flat=$(mktemp "$dest.XXXXXX.tif")
        work_src=$(flatten_if_alpha "$src" "$bg" "$tmp_flat")
    fi

    if vips dzsave "$work_src" "$dest" \
        --layout google --centre --suffix .webp[Q=95,near_lossless=true] \
        --tile-size 256 --background "$bg" 2>/dev/null; then
        result="webp-near_lossless"
        suffix_used=".webp"
        echo "Tiles: $label (webp near_lossless)"
    elif vips dzsave "$work_src" "$dest" \
        --layout google --centre --suffix .webp[Q=95] \
        --tile-size 256 --background "$bg" 2>/dev/null; then
        result="webp-Q95"
        suffix_used=".webp"
        echo "Tiles: $label (webp Q=95)"
    elif vips dzsave "$work_src" "$dest" \
        --layout google --centre \
        --tile-size 256 --background "$bg" 2>/dev/null; then
        result="jpeg-default"
        suffix_used=".jpg"
        echo "Tiles: $label (JPEG default)"
    elif vips dzsave "$work_src" "$dest" \
        --layout google --centre --suffix .png \
        --tile-size 256 --background "$bg" 2>/dev/null; then
        result="png"
        suffix_used=".png"
        echo "Tiles: $label (PNG)"
    else
        rm -rf "$dest"
        result="FAILED"
        suffix_used=""
        echo "Tiles: $label FAILED (all strategies exhausted)"
    fi

    [ -f "$tmp_flat" ] && rm -f "$tmp_flat"

    echo "$result:$suffix_used"
}

to_vips_background() {
    local raw="$1"
    local color="${raw,,}"
    color="${color// /}"
    color="${color//\"/}"

    case "$color" in
        ""|white|\#fff|\#ffffff)
            echo "255 255 255"
            return
            ;;
        black|\#000|\#000000)
            echo "0 0 0"
            return
            ;;
    esac

    if [[ "$color" =~ ^#([0-9a-f]{6})$ ]]; then
        local hex="${BASH_REMATCH[1]}"
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        echo "$r $g $b"
        return
    fi

    if [[ "$color" =~ ^#([0-9a-f]{3})$ ]]; then
        local hex="${BASH_REMATCH[1]}"
        local r=$((16#${hex:0:1}${hex:0:1}))
        local g=$((16#${hex:1:1}${hex:1:1}))
        local b=$((16#${hex:2:1}${hex:2:1}))
        echo "$r $g $b"
        return
    fi

    echo "255 255 255"
}

normalize_image_name() {
    local raw="$1"
    local name="$raw"

    # Trim surrounding whitespace.
    name="$(echo "$name" | awk '{$1=$1; print}')"

    # Support Obsidian wikilinks like [[image.png]] or [[image.png|Alias]].
    name="${name#\[\[}"
    name="${name%\]\]}"
    name="${name#\!}"
    name="${name%%|*}"

    # Trim again after link normalization.
    name="$(echo "$name" | awk '{$1=$1; print}')"

    echo "$name"
}

resolve_image_name() {
    local name="$1"

    if [[ "$name" == *.* ]]; then
        if [ -f "$SRC_IMAGE_DIR/$name" ]; then
            echo "$name"
            return
        fi
        # Search all of vault/assets if not in default dir
        local found=$(find "./vault/assets" -type f -name "$name" -print -quit)
        if [ -n "$found" ]; then
            echo "$name"
            return
        fi
        echo "$name"
        return
    fi

    local matches=()
    while IFS= read -r found; do
        matches+=("$found")
    done < <(find "$SRC_IMAGE_DIR" -maxdepth 1 -type f -iname "$name.*" -printf '%f\n' | sort)

    if [ "${#matches[@]}" -eq 0 ]; then
        # If no matches in primary dir, search all of vault/assets
        while IFS= read -r found; do
            matches+=("$found")
        done < <(find "./vault/assets" -type f -iname "$name.*" -printf '%f\n' | sort)
    fi

    if [ "${#matches[@]}" -eq 1 ]; then
        echo "${matches[0]}"
        return
    fi

    if [ "${#matches[@]}" -gt 1 ]; then
        for preferred_ext in png jpg jpeg webp gif; do
            for candidate in "${matches[@]}"; do
                if [[ "${candidate,,}" == "$name.$preferred_ext" ]]; then
                    echo "$candidate"
                    return
                fi
            done
        done
        echo "${matches[0]}"
        return
    fi

    echo "$name"
}

file_checksum() {
    local file="$1"

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
        return
    fi

    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
        return
    fi

    # Very portable fallback.
    cksum "$file" | awk '{print $1 "-" $2}'
}

all_files_exist() {
    for f in "$@"; do
        if [ ! -f "$f" ]; then
            return 1
        fi
    done
    return 0
}

copy_download_variant() {
    local src_dir="$1"
    local target_dir="$2"
    local default_name="$3"
    local configured_name="$4"
    local label="$5"

    local variant_name=""
    if [ "$configured_name" = "true" ]; then
        variant_name="$default_name"
    elif [ -n "$configured_name" ] && [ "$configured_name" != "null" ] && [ "$configured_name" != "false" ]; then
        variant_name="$configured_name"
    fi

    if [ -z "$variant_name" ]; then
        return
    fi

    local src_variant="$src_dir/$variant_name"
    if [ ! -f "$src_variant" ]; then
        local found_variant
        found_variant=$(find "./vault/assets" -type f -name "$variant_name" -print -quit)
        if [ -n "$found_variant" ]; then
            src_variant="$found_variant"
        fi
    fi

    local dest_variant="$target_dir/$variant_name"
    if [ -f "$src_variant" ]; then
        cp "$src_variant" "$dest_variant"
        echo "Copied $label variant for $IMG_NAME: $variant_name"
    else
        echo "Warning: $label variant not found for $IMG_NAME: $src_variant"
    fi
}

# Read the template file
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Template file not found: $TEMPLATE_FILE"
    echo "Please create the template file first."
    exit 1
fi

echo "Reading template from: $TEMPLATE_FILE"
TEMPLATE_HTML=$(cat "$TEMPLATE_FILE")

if [ -z "$TEMPLATE_HTML" ]; then
    echo "Template file is empty or could not be read"
    exit 1
fi

mkdir -p "$DEST_IMAGE_DIR"
mkdir -p "$MAPS_HTML_DIR"
mkdir -p "$(dirname "$SIZE_DATA_FILE")"

# Initialize or load existing size data
if [ -f "$SIZE_DATA_FILE" ]; then
    echo "Loading existing size data from $SIZE_DATA_FILE"
else
    echo "Creating new size data file at $SIZE_DATA_FILE"
    echo "# Image aspect ratios (width/height)" > "$SIZE_DATA_FILE"
fi

# Function to update size data
update_size_data() {
    local img_name="$1"
    local small_ratio="$2"
    local medium_ratio="$3"
    
    # Create temporary YAML entry
    local temp_entry="$img_name:
  small: $small_ratio
  medium: $medium_ratio"
    
    # Check if entry exists and update or append
    if grep -q "^$img_name:" "$SIZE_DATA_FILE"; then
        # Update existing entry using yq
        echo "$temp_entry" | yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$SIZE_DATA_FILE" - > "${SIZE_DATA_FILE}.tmp"
        mv "${SIZE_DATA_FILE}.tmp" "$SIZE_DATA_FILE"
    else
        # Append new entry
        echo "" >> "$SIZE_DATA_FILE"
        echo "$temp_entry" >> "$SIZE_DATA_FILE"
    fi
}

extract_content_image_links() {
    local md_file="$1"

    awk '
        BEGIN { in_fm=0; fm_done=0 }
        /^---[[:space:]]*$/ {
            if (fm_done == 0) {
                in_fm = !in_fm
                if (in_fm == 0) fm_done = 1
                next
            }
        }
        { if (fm_done == 1 || in_fm == 0) print }
    ' "$md_file" \
    | grep -oEi '!\[\[[^]]+(\|[^]]*)?\]\]|\[\[[^]]+(\|[^]]*)?\]\]' \
    | sed -E 's/^!?\[\[//; s/\]\]$//; s/\|.*$//' \
    || true
}

process_image_entry() {
    PATHMD="_${MD_FILE#*_}"
    TILE_LIGHT_BG=$(to_vips_background "$BG")
    ACTIVE_DARKIFY_INVERT_LEVEL_DEFAULT="$DARKIFY_INVERT_LEVEL_DEFAULT"
    ACTIVE_DARKIFY_INVERT_LEVEL_SMALL="$DARKIFY_INVERT_LEVEL_SMALL"
    ACTIVE_DARKIFY_INVERT_LEVEL_MEDIUM="$DARKIFY_INVERT_LEVEL_MEDIUM"
    ACTIVE_DARKIFY_INVERT_LEVEL_LARGE="$DARKIFY_INVERT_LEVEL_LARGE"

    if [ -n "$IMG_DARKIFY_INVERT_LEVEL_DEFAULT" ] && [ "$IMG_DARKIFY_INVERT_LEVEL_DEFAULT" != "null" ]; then
        ACTIVE_DARKIFY_INVERT_LEVEL_DEFAULT="$IMG_DARKIFY_INVERT_LEVEL_DEFAULT"
    fi
    if [ -n "$IMG_DARKIFY_INVERT_LEVEL_SMALL" ] && [ "$IMG_DARKIFY_INVERT_LEVEL_SMALL" != "null" ]; then
        ACTIVE_DARKIFY_INVERT_LEVEL_SMALL="$IMG_DARKIFY_INVERT_LEVEL_SMALL"
    fi
    if [ -n "$IMG_DARKIFY_INVERT_LEVEL_MEDIUM" ] && [ "$IMG_DARKIFY_INVERT_LEVEL_MEDIUM" != "null" ]; then
        ACTIVE_DARKIFY_INVERT_LEVEL_MEDIUM="$IMG_DARKIFY_INVERT_LEVEL_MEDIUM"
    fi
    if [ -n "$IMG_DARKIFY_INVERT_LEVEL_LARGE" ] && [ "$IMG_DARKIFY_INVERT_LEVEL_LARGE" != "null" ]; then
        ACTIVE_DARKIFY_INVERT_LEVEL_LARGE="$IMG_DARKIFY_INVERT_LEVEL_LARGE"
    fi

    if [ -z "$IMG_NAME" ] || [ "$IMG_NAME" = "null" ]; then
        echo "Skipping image entry with empty/invalid name in $MD_FILE"
        return
    fi

    echo "Found image: $IMG_NAME (map: $MAP)"

    # Resolve source path by searching vault/assets/ if not in default location
    SRC_IMG_PATH="$SRC_IMAGE_DIR/$IMG_NAME"
    if [ ! -f "$SRC_IMG_PATH" ]; then
        FOUND_PATH=$(find "./vault/assets" -type f -name "$IMG_NAME" -print -quit)
        if [ -n "$FOUND_PATH" ]; then
            SRC_IMG_PATH="$FOUND_PATH"
        fi
    fi

    EXT="${IMG_NAME##*.}"
    IMG_BASE="${IMG_NAME%.*}"
    DEST_FOLDER="$DEST_IMAGE_DIR/$IMG_BASE"
    DARK_IMG_NAME="${IMG_BASE}-${DARKIFY_SUFFIX}.${EXT}"
    DARK_IMG_PATH="$DEST_FOLDER/$DARK_IMG_NAME"
    ASSET_META_FILE="$DEST_FOLDER/asset-meta.txt"
    NEEDS_DARKIFY="false"
    if [ "$IMG_DARK" != "true" ]; then
        NEEDS_DARKIFY="true"
    fi

    if [ ! -f "$SRC_IMG_PATH" ]; then
        echo "Image not found: $SRC_IMG_PATH"
        return
    fi

    mkdir -p "$DEST_FOLDER"
    SRC_HASH=$(file_checksum "$SRC_IMG_PATH")
    CURRENT_META=$(cat <<EOF
meta_version=$ASSET_META_VERSION
src_name=$IMG_NAME
src_hash=$SRC_HASH
map=$MAP
display=$DISPLAY
file=$FILE
bg=$BG
tile_light_bg=$TILE_LIGHT_BG
img_dark=$IMG_DARK
needs_darkify=$NEEDS_DARKIFY
darkify_method=$DARKIFY_METHOD
darkify_suffix=$DARKIFY_SUFFIX
darkify_invert_level_default=$ACTIVE_DARKIFY_INVERT_LEVEL_DEFAULT
darkify_invert_level_small=$ACTIVE_DARKIFY_INVERT_LEVEL_SMALL
darkify_invert_level_medium=$ACTIVE_DARKIFY_INVERT_LEVEL_MEDIUM
darkify_invert_level_large=$ACTIVE_DARKIFY_INVERT_LEVEL_LARGE
EOF
)
    META_MATCH="false"
    if [ -f "$ASSET_META_FILE" ] && [ "$(cat "$ASSET_META_FILE")" = "$CURRENT_META" ]; then
        META_MATCH="true"
    fi

    if [ "$MAPS_HTML_ONLY" != "true" ]; then
        if [ "$META_MATCH" = "true" ] && [ -f "$DEST_FOLDER/$IMG_NAME" ]; then
            echo "Skipping original copy for $IMG_NAME (unchanged)"
        else
            cp "$SRC_IMG_PATH" "$DEST_FOLDER/$IMG_NAME"
        fi

        if [ "$FILE" = "true" ]; then
            copy_download_variant \
                "$SRC_DOWNLOAD_PDF_DIR" \
                "$DEST_FOLDER" \
                "$IMG_BASE.pdf" \
                "$IMG_PDF" \
                "PDF"
            copy_download_variant \
                "$SRC_DOWNLOAD_SVG_DIR" \
                "$DEST_FOLDER" \
                "$IMG_BASE.svg" \
                "$IMG_SVG" \
                "SVG"
        fi
    fi

    NEEDS_DARK_FILE="false"
    if [ "$NEEDS_DARKIFY" = "true" ] && [ "$FILE" = "true" ]; then
        NEEDS_DARK_FILE="true"
    fi

    if [ "$NEEDS_DARK_FILE" = "true" ] && [ "$MAPS_HTML_ONLY" != "true" ]; then
        if [ "$META_MATCH" = "true" ] && [ -f "$DARK_IMG_PATH" ]; then
            echo "Skipping dark version for $IMG_NAME (unchanged)"
        else
            echo "Generating dark version for $IMG_NAME (method: $DARKIFY_METHOD)"
            ensure_magick
            if ! darkify_image "$SRC_IMG_PATH" "$DARK_IMG_PATH" "$DARKIFY_METHOD"; then
                echo "Warning: dark generation failed for $IMG_NAME (likely ImageMagick resource limits)."
                echo "Falling back to original image for dark download variant: $DARK_IMG_NAME"
                rm -f "$DARK_IMG_PATH"
                cp "$SRC_IMG_PATH" "$DARK_IMG_PATH"
            fi
        fi
    fi

    if [ "$DISPLAY" = "true" ] && [ "$MAPS_HTML_ONLY" != "true" ]; then
        THUMB_SMALL="$DEST_FOLDER/small.webp"
        THUMB_MEDIUM="$DEST_FOLDER/medium.webp"
        DARK_THUMB_SMALL="$DEST_FOLDER/small-${DARKIFY_SUFFIX}.webp"
        DARK_THUMB_MEDIUM="$DEST_FOLDER/medium-${DARKIFY_SUFFIX}.webp"

        THUMBS_UP_TO_DATE="false"
        if [ "$META_MATCH" = "true" ] \
            && all_files_exist "$THUMB_SMALL" "$THUMB_MEDIUM"; then
            if [ "$NEEDS_DARKIFY" = "true" ]; then
                if all_files_exist "$DARK_THUMB_SMALL" "$DARK_THUMB_MEDIUM"; then
                    THUMBS_UP_TO_DATE="true"
                fi
            else
                THUMBS_UP_TO_DATE="true"
            fi
        fi

        if [ "$THUMBS_UP_TO_DATE" = "true" ]; then
            echo "Skipping thumbnails for $IMG_NAME (unchanged)"
        else
            echo "Processing displayable asset: $IMG_NAME (generating thumbnails)"

            ORIG_WIDTH=$(vipsheader -f width "$SRC_IMG_PATH")
            ORIG_HEIGHT=$(vipsheader -f height "$SRC_IMG_PATH")
            ASPECT_RATIO=$(awk "BEGIN {printf \"%.3f\", $ORIG_WIDTH / $ORIG_HEIGHT}")

            if [ $(awk "BEGIN {print ($ASPECT_RATIO <= 0.8)}") -eq 1 ]; then
                SMALL_SIZE=565
                MEDIUM_SIZE=1131
                echo "Tall image detected (ratio: $ASPECT_RATIO) - using increased resolution"
            else
                SMALL_SIZE=400
                MEDIUM_SIZE=800
                echo "Square/wide image detected (ratio: $ASPECT_RATIO) - using standard resolution"
            fi

            # Q=90 reduces banding on dark backgrounds vs Q=75
            vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/small.webp[Q=90]" $SMALL_SIZE --intent relative
            vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/medium.webp[Q=90]" $MEDIUM_SIZE --intent relative

            if [ "$NEEDS_DARKIFY" = "true" ]; then
                ensure_magick
                darkify_image "$THUMB_SMALL" "$DARK_THUMB_SMALL" "$DARKIFY_METHOD" "thumb-small"
                darkify_image "$THUMB_MEDIUM" "$DARK_THUMB_MEDIUM" "$DARKIFY_METHOD" "thumb-medium"
            fi
        fi

        SMALL_WIDTH=$(vipsheader -f width "$DEST_FOLDER/small.webp")
        SMALL_HEIGHT=$(vipsheader -f height "$DEST_FOLDER/small.webp")
        SMALL_RATIO=$(awk "BEGIN {printf \"%.3f\", $SMALL_WIDTH / $SMALL_HEIGHT}")

        MEDIUM_WIDTH=$(vipsheader -f width "$DEST_FOLDER/medium.webp")
        MEDIUM_HEIGHT=$(vipsheader -f height "$DEST_FOLDER/medium.webp")
        MEDIUM_RATIO=$(awk "BEGIN {printf \"%.3f\", $MEDIUM_WIDTH / $MEDIUM_HEIGHT}")

        update_size_data "$IMG_BASE" "$SMALL_RATIO" "$MEDIUM_RATIO"
        echo "Stored aspect ratios for $IMG_BASE: small=$SMALL_RATIO, medium=$MEDIUM_RATIO"
    else
        echo "Skipping thumbnail generation for non-displayable asset: $IMG_NAME"
    fi

    if [ "$MAP" = "true" ]; then
        TILE_PATH="$DEST_FOLDER/tiles"
        TILE_DARK_PATH="$DEST_FOLDER/tiles-dark"
        TILE_DARK_BG="0 0 0"

        echo "Processing $IMG_NAME..."

        WIDTH=$(vipsheader -f width "$SRC_IMG_PATH")
        HEIGHT=$(vipsheader -f height "$SRC_IMG_PATH")

        if [ "$MAPS_HTML_ONLY" = "true" ]; then
            echo "Skipping tile generation (MAPS_HTML_ONLY=true)."
        else
            LIGHT_TILES_UP_TO_DATE="false"
            if [ "$META_MATCH" = "true" ] && [[ -d "$TILE_PATH" ]]; then
                LIGHT_TILES_UP_TO_DATE="true"
            fi

            if [ "$LIGHT_TILES_UP_TO_DATE" = "true" ]; then
                echo "Skipping $IMG_NAME light tiles (unchanged)."
            else
                LIGHT_TILE_RESULT=$(generate_tiles "$SRC_IMG_PATH" "$TILE_PATH" "$TILE_LIGHT_BG" "light")
                LIGHT_TILE_STATUS="${LIGHT_TILE_RESULT%%:*}"
                if [ "$LIGHT_TILE_STATUS" = "FAILED" ]; then
                    HAS_DARK_TILES="false"
                fi
                TILE_GENERATION_LOG="${TILE_GENERATION_LOG}light:${IMG_NAME}:${LIGHT_TILE_RESULT}\n"
            fi
        fi

        HAS_DARK_TILES="false"
        NEEDS_DARK_TILES="false"
        if [ "$NEEDS_DARKIFY" = "true" ] || [ "$IMG_DARK" = "true" ]; then
            NEEDS_DARK_TILES="true"
        fi
        if [ "$NEEDS_DARK_TILES" = "true" ]; then
            HAS_DARK_TILES="true"
            if [ "$MAPS_HTML_ONLY" = "true" ]; then
                if [[ ! -d "$TILE_DARK_PATH" ]]; then
                    HAS_DARK_TILES="false"
                fi
                echo "Skipping dark tile generation (MAPS_HTML_ONLY=true)."
            else
                DARK_TILES_UP_TO_DATE="false"
                if [ "$META_MATCH" = "true" ] && [[ -d "$TILE_DARK_PATH" ]]; then
                    DARK_TILES_UP_TO_DATE="true"
                fi

                if [ "$DARK_TILES_UP_TO_DATE" = "true" ]; then
                    echo "Skipping $IMG_NAME dark tiles (unchanged)."
                else
                    if [ "$IMG_DARK" = "true" ]; then
                        DARK_TILE_RESULT=$(generate_tiles "$SRC_IMG_PATH" "$TILE_DARK_PATH" "$TILE_DARK_BG" "dark")
                        DARK_TILE_STATUS="${DARK_TILE_RESULT%%:*}"
                        if [ "$DARK_TILE_STATUS" = "FAILED" ]; then
                            HAS_DARK_TILES="false"
                        fi
                        TILE_GENERATION_LOG="${TILE_GENERATION_LOG}dark:${IMG_NAME}:${DARK_TILE_RESULT}\n"
                    else
                        ensure_magick
                        if ! darkify_tile_set "$TILE_PATH" "$TILE_DARK_PATH" "$DARKIFY_METHOD" 2>&1; then
                            echo "Warning: darkify_tile_set failed for $IMG_NAME"
                            rm -rf "$TILE_DARK_PATH"
                            HAS_DARK_TILES="false"
                            TILE_GENERATION_LOG="${TILE_GENERATION_LOG}dark:${IMG_NAME}:darkify_FAILED\n"
                        else
                            TILE_GENERATION_LOG="${TILE_GENERATION_LOG}dark:${IMG_NAME}:darkify_success\n"
                        fi
                    fi
                fi
            fi
        fi

        HTML_FILE="$MAPS_HTML_DIR/${IMG_BASE}.md"

        echo "Creating HTML viewer for $IMG_NAME at $HTML_FILE"

        printf '%s' "$TEMPLATE_HTML" \
            | sed "s/__IMG_NAME__/$IMG_BASE/g" \
            | sed "s/__WIDTH__/$WIDTH/g" \
            | sed "s/__HEIGHT__/$HEIGHT/g" \
            | sed "s/__BG__/$BG/g" \
            | sed "s/__HAS_DARK_TILES__/$HAS_DARK_TILES/g" \
            | sed "s/__TITLE__/$(printf '%s\n' "$PAGE_TITLE" | sed 's/[&/\]/\\&/g')/g" \
            | sed "s|__PATHMD__|$PATHMD|g" \
            > "$HTML_FILE"
    fi

    if [ "$MAPS_HTML_ONLY" != "true" ]; then
        printf '%s\n' "$CURRENT_META" > "$ASSET_META_FILE"
    fi

    echo "Processed: $IMG_NAME (map: $MAP)"
}

# Loop through all markdown files
find "$MD_DIR" -type f -name "*.md" | while read -r MD_FILE; do
    YAML=$(awk '/^---/{flag=!flag; next} flag' "$MD_FILE")
    PUBLISHED=$(echo "$YAML" | yq -r '.published // false')
    if [ "$PUBLISHED" != "true" ]; then
        continue
    fi
    PAGE_TITLE=$(echo "$YAML" | yq -r '.title // "Untitled Map"')
    IS_SEQ=$(echo "$YAML" | yq '(.images | type) == "!!seq"')
    if [ "$IS_SEQ" != "true" ]; then
        IMG_COUNT=0
    else
        IMG_COUNT=$(echo "$YAML" | yq '.images | length')
    fi
    declare -A PROCESSED_IMAGES=()

    for ((i=0; i<IMG_COUNT; i++)); do
        RAW_IMG_NAME=$(echo "$YAML" | yq -r ".images[$i].name // .images[$i] // \"\"")
        IMG_NAME=$(resolve_image_name "$(normalize_image_name "$RAW_IMG_NAME")")
        MAP=$(echo "$YAML" | yq -r ".images[$i].map // false")
        BG=$(echo "$YAML" | yq -r ".images[$i].background // \"white\"")
        IMG_DARK=$(echo "$YAML" | yq -r ".images[$i].dark // false")
        DISPLAY=$(echo "$YAML" | yq -r ".images[$i].display // true") # Default to true
        FILE=$(echo "$YAML" | yq -r ".images[$i].file // false")     # Default to false
        IMG_PDF=$(echo "$YAML" | yq -r ".images[$i].pdf // \"\"")
        IMG_SVG=$(echo "$YAML" | yq -r ".images[$i].svg // \"\"")
        IMG_DARKIFY_INVERT_LEVEL_DEFAULT=$(echo "$YAML" | yq -r ".images[$i].invert_level.default // \"\"")
        IMG_DARKIFY_INVERT_LEVEL_SMALL=$(echo "$YAML" | yq -r ".images[$i].invert_level.small // \"\"")
        IMG_DARKIFY_INVERT_LEVEL_MEDIUM=$(echo "$YAML" | yq -r ".images[$i].invert_level.medium // \"\"")
        IMG_DARKIFY_INVERT_LEVEL_LARGE=$(echo "$YAML" | yq -r ".images[$i].invert_level.large // \"\"")
        if [ -n "$IMG_NAME" ] && [ "$IMG_NAME" != "null" ] && [ -z "${PROCESSED_IMAGES[$IMG_NAME]}" ]; then
            process_image_entry
            PROCESSED_IMAGES[$IMG_NAME]=1
        fi
    done

    RAW_PAGE_IMAGE=$(echo "$YAML" | yq -r '.image // ""')
    IMG_NAME=$(resolve_image_name "$(normalize_image_name "$RAW_PAGE_IMAGE")")
    if [ -n "$IMG_NAME" ] && [ "$IMG_NAME" != "null" ] && [ -z "${PROCESSED_IMAGES[$IMG_NAME]}" ]; then
        MAP="false"
        BG="white"
        IMG_DARK="true"
        DISPLAY="true"
        FILE="false"
        IMG_PDF=""
        IMG_SVG=""
        IMG_DARKIFY_INVERT_LEVEL_DEFAULT=""
        IMG_DARKIFY_INVERT_LEVEL_SMALL=""
        IMG_DARKIFY_INVERT_LEVEL_MEDIUM=""
        IMG_DARKIFY_INVERT_LEVEL_LARGE=""
        process_image_entry
        PROCESSED_IMAGES[$IMG_NAME]=1
    fi

    while read -r RAW_CONTENT_IMAGE; do
        [ -z "$RAW_CONTENT_IMAGE" ] && continue
        IMG_NAME=$(resolve_image_name "$(normalize_image_name "$RAW_CONTENT_IMAGE")")
        if [ -z "$IMG_NAME" ] || [ "$IMG_NAME" = "null" ] || [ -n "${PROCESSED_IMAGES[$IMG_NAME]}" ]; then
            continue
        fi
        if [ ! -f "$SRC_IMAGE_DIR/$IMG_NAME" ]; then
            continue
        fi

        MAP="false"
        BG="white"
        IMG_DARK="true"
        DISPLAY="true"
        FILE="false"
        IMG_PDF=""
        IMG_SVG=""
        IMG_DARKIFY_INVERT_LEVEL_DEFAULT=""
        IMG_DARKIFY_INVERT_LEVEL_SMALL=""
        IMG_DARKIFY_INVERT_LEVEL_MEDIUM=""
        IMG_DARKIFY_INVERT_LEVEL_LARGE=""
        process_image_entry
        PROCESSED_IMAGES[$IMG_NAME]=1
    done < <(extract_content_image_links "$MD_FILE")
done

# Ensure file sizes are updated for tooltips
if [ -f "scripts/generate_file_sizes.sh" ]; then
    bash scripts/generate_file_sizes.sh
fi

echo "Aspect ratio data has been updated in $SIZE_DATA_FILE"

if [ -n "$TILE_GENERATION_LOG" ]; then
    echo ""
    echo "=== Tile Generation Summary ==="
    echo -e "$TILE_GENERATION_LOG" | column -t -s':'
fi
