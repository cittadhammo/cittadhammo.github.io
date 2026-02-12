#!/bin/bash
set -e

SRC_IMAGE_DIR="./vault/assets/images"
DEST_IMAGE_DIR="./assets/images"
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

MAGICK_AVAILABLE="unknown"
ensure_magick() {
    if [ "$MAGICK_AVAILABLE" = "unknown" ]; then
        if command -v magick >/dev/null 2>&1; then
            MAGICK_AVAILABLE="true"
        else
            MAGICK_AVAILABLE="false"
        fi
    fi
    if [ "$MAGICK_AVAILABLE" != "true" ]; then
        echo "ImageMagick 'magick' not found in PATH. Install ImageMagick to enable darkify."
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

to_vips_background() {
    local raw="$1"
    local color="${raw,,}"
    color="${color// /}"
    color="${color//\"/}"

    case "$color" in
        ""|white|\#fff|\#ffffff)
            echo "255,255,255"
            return
            ;;
        black|\#000|\#000000)
            echo "0,0,0"
            return
            ;;
    esac

    if [[ "$color" =~ ^#([0-9a-f]{6})$ ]]; then
        local hex="${BASH_REMATCH[1]}"
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        echo "$r,$g,$b"
        return
    fi

    if [[ "$color" =~ ^#([0-9a-f]{3})$ ]]; then
        local hex="${BASH_REMATCH[1]}"
        local r=$((16#${hex:0:1}${hex:0:1}))
        local g=$((16#${hex:1:1}${hex:1:1}))
        local b=$((16#${hex:2:1}${hex:2:1}))
        echo "$r,$g,$b"
        return
    fi

    # Fallback keeps old behavior if background is missing/unknown.
    echo "255,255,255"
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
    local large_ratio="$4"
    
    # Create temporary YAML entry
    local temp_entry="$img_name:
  small: $small_ratio
  medium: $medium_ratio
  large: $large_ratio"
    
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

# Loop through all markdown files
find "$MD_DIR" -type f -name "*.md" | while read -r MD_FILE; do
    YAML=$(awk '/^---/{flag=!flag; next} flag' "$MD_FILE")
    PAGE_TITLE=$(echo "$YAML" | yq -r '.title // "Untitled Map"')
    IMG_COUNT=$(echo "$YAML" | yq '.images | length')

    for ((i=0; i<IMG_COUNT; i++)); do
        RAW_IMG_NAME=$(echo "$YAML" | yq -r ".images[$i].name // .images[$i] // \"\"")
        IMG_NAME=$(normalize_image_name "$RAW_IMG_NAME")
        MAP=$(echo "$YAML" | yq -r ".images[$i].map // false")
        BG=$(echo "$YAML" | yq -r ".images[$i].background // \"white\"")
        TILE_LIGHT_BG=$(to_vips_background "$BG")
        IMG_DARK=$(echo "$YAML" | yq -r ".images[$i].dark // false")
        DISPLAY=$(echo "$YAML" | yq -r ".images[$i].display // true") # Default to true
        FILE=$(echo "$YAML" | yq -r ".images[$i].file // false")     # Default to false
        PATHMD="_${MD_FILE#*_}"

        if [ -z "$IMG_NAME" ] || [ "$IMG_NAME" = "null" ]; then
            echo "Skipping image entry with empty/invalid name in $MD_FILE"
            continue
        fi

        echo "Found image: $IMG_NAME (map: $MAP)"
        

        SRC_IMG_PATH="$SRC_IMAGE_DIR/$IMG_NAME"
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
            continue
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
        fi

        if [ "$NEEDS_DARKIFY" = "true" ] && [ "$MAPS_HTML_ONLY" != "true" ]; then
            if [ "$META_MATCH" = "true" ] && [ -f "$DARK_IMG_PATH" ]; then
                echo "Skipping dark version for $IMG_NAME (unchanged)"
            else
                echo "Generating dark version for $IMG_NAME (method: $DARKIFY_METHOD)"
                ensure_magick
                darkify_image "$SRC_IMG_PATH" "$DARK_IMG_PATH" "$DARKIFY_METHOD"
            fi
        fi

        if [ "$DISPLAY" = "true" ] && [ "$MAPS_HTML_ONLY" != "true" ]; then
            THUMB_SMALL="$DEST_FOLDER/small.webp"
            THUMB_MEDIUM="$DEST_FOLDER/medium.webp"
            THUMB_LARGE="$DEST_FOLDER/large.webp"
            DARK_THUMB_SMALL="$DEST_FOLDER/small-${DARKIFY_SUFFIX}.webp"
            DARK_THUMB_MEDIUM="$DEST_FOLDER/medium-${DARKIFY_SUFFIX}.webp"
            DARK_THUMB_LARGE="$DEST_FOLDER/large-${DARKIFY_SUFFIX}.webp"

            THUMBS_UP_TO_DATE="false"
            if [ "$META_MATCH" = "true" ] \
                && all_files_exist "$THUMB_SMALL" "$THUMB_MEDIUM" "$THUMB_LARGE"; then
                if [ "$NEEDS_DARKIFY" = "true" ]; then
                    if all_files_exist "$DARK_THUMB_SMALL" "$DARK_THUMB_MEDIUM" "$DARK_THUMB_LARGE"; then
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

                # Get aspect ratio to determine appropriate sizing
                ORIG_WIDTH=$(vipsheader -f width "$SRC_IMG_PATH")
                ORIG_HEIGHT=$(vipsheader -f height "$SRC_IMG_PATH")
                ASPECT_RATIO=$(awk "BEGIN {printf \"%.3f\", $ORIG_WIDTH / $ORIG_HEIGHT}")

                # Use different sizes based on aspect ratio - A4 and taller images get more resolution
                if [ $(awk "BEGIN {print ($ASPECT_RATIO <= 0.8)}") -eq 1 ]; then
                    # Tall images (A4 ratio and taller) - increase resolution to match visual space
                    SMALL_SIZE=565   # ~41% more than 400
                    MEDIUM_SIZE=1131 # ~41% more than 800  
                    LARGE_SIZE=2263  # ~41% more than 1600
                    echo "Tall image detected (ratio: $ASPECT_RATIO) - using increased resolution"
                else
                    # Square and wide images - standard resolution
                    SMALL_SIZE=400
                    MEDIUM_SIZE=800
                    LARGE_SIZE=1600
                    echo "Square/wide image detected (ratio: $ASPECT_RATIO) - using standard resolution"
                fi

                # Generate WebP thumbnails with appropriate sizing
                vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/small.webp[Q=95,near_lossless=true]" $SMALL_SIZE --intent relative
                vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/medium.webp[Q=95,near_lossless=true]" $MEDIUM_SIZE --intent relative
                vips thumbnail "$SRC_IMG_PATH" "$DEST_FOLDER/large.webp[Q=95,near_lossless=true]" $LARGE_SIZE --intent relative

                if [ "$NEEDS_DARKIFY" = "true" ]; then
                    vips thumbnail "$DARK_IMG_PATH" "$DEST_FOLDER/small-${DARKIFY_SUFFIX}.webp[Q=95,near_lossless=true]" $SMALL_SIZE --intent relative
                    vips thumbnail "$DARK_IMG_PATH" "$DEST_FOLDER/medium-${DARKIFY_SUFFIX}.webp[Q=95,near_lossless=true]" $MEDIUM_SIZE --intent relative
                    vips thumbnail "$DARK_IMG_PATH" "$DEST_FOLDER/large-${DARKIFY_SUFFIX}.webp[Q=95,near_lossless=true]" $LARGE_SIZE --intent relative
                fi
            fi

            # Get aspect ratios of generated thumbnails (width/height)
            SMALL_WIDTH=$(vipsheader -f width "$DEST_FOLDER/small.webp")
            SMALL_HEIGHT=$(vipsheader -f height "$DEST_FOLDER/small.webp")
            SMALL_RATIO=$(awk "BEGIN {printf \"%.3f\", $SMALL_WIDTH / $SMALL_HEIGHT}")

            MEDIUM_WIDTH=$(vipsheader -f width "$DEST_FOLDER/medium.webp")
            MEDIUM_HEIGHT=$(vipsheader -f height "$DEST_FOLDER/medium.webp")
            MEDIUM_RATIO=$(awk "BEGIN {printf \"%.3f\", $MEDIUM_WIDTH / $MEDIUM_HEIGHT}")

            LARGE_WIDTH=$(vipsheader -f width "$DEST_FOLDER/large.webp")
            LARGE_HEIGHT=$(vipsheader -f height "$DEST_FOLDER/large.webp")
            LARGE_RATIO=$(awk "BEGIN {printf \"%.3f\", $LARGE_WIDTH / $LARGE_HEIGHT}")

            # Update size data file
            update_size_data "$IMG_BASE" "$SMALL_RATIO" "$MEDIUM_RATIO" "$LARGE_RATIO"
            
            echo "Stored aspect ratios for $IMG_BASE: small=$SMALL_RATIO, medium=$MEDIUM_RATIO, large=$LARGE_RATIO"
        else
            echo "Skipping thumbnail generation for non-displayable asset: $IMG_NAME"
        fi # End of processing displayable asset

        if [ "$MAP" = "true" ]; then
            TILE_PATH="$DEST_FOLDER/tiles"
            TILE_DARK_PATH="$DEST_FOLDER/tiles-dark"

            echo "Processing $IMG_NAME..."

            # read WIDTH HEIGHT <<< $(identify -format "%w %h" "$SRC_IMG_PATH")
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
                    rm -rf "$TILE_PATH"
                    mkdir -p "$TILE_PATH"
                vips dzsave "$SRC_IMG_PATH" "$TILE_PATH" \
                    --layout google --centre --suffix .webp[Q=95,near_lossless=true] \
                    --tile-size 256 --background "$TILE_LIGHT_BG" --vips-progress
                fi
            fi

            HAS_DARK_TILES="false"
            if [ "$NEEDS_DARKIFY" = "true" ]; then
                if [ "$MAPS_HTML_ONLY" = "true" ]; then
                    if [[ -d "$TILE_DARK_PATH" ]]; then
                        HAS_DARK_TILES="true"
                    fi
                    echo "Skipping dark tile generation (MAPS_HTML_ONLY=true)."
                else
                    HAS_DARK_TILES="true"
                    DARK_TILES_UP_TO_DATE="false"
                    if [ "$META_MATCH" = "true" ] && [[ -d "$TILE_DARK_PATH" ]]; then
                        DARK_TILES_UP_TO_DATE="true"
                    fi

                    if [ "$DARK_TILES_UP_TO_DATE" = "true" ]; then
                        echo "Skipping $IMG_NAME dark tiles (unchanged)."
                    else
                        rm -rf "$TILE_DARK_PATH"
                        mkdir -p "$TILE_DARK_PATH"
                        vips dzsave "$DARK_IMG_PATH" "$TILE_DARK_PATH" \
                            --layout google --centre --suffix .webp[Q=95,near_lossless=true] \
                            --tile-size 256 --background "0,0,0" --vips-progress
                    fi
                fi
            fi

            HTML_FILE="$MAPS_HTML_DIR/${IMG_BASE}.md"

            echo "Creating HTML viewer for $IMG_NAME at $HTML_FILE"

            # Use printf instead of echo to avoid quote issues
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
    done
done

echo "Aspect ratio data has been updated in $SIZE_DATA_FILE"
