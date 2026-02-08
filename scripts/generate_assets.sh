#!/bin/bash
set -e

SRC_IMAGE_DIR="./vault/assets/images/"
DEST_IMAGE_DIR="./assets/images"
MD_DIR="./vault/content" 
MAPS_HTML_DIR="./maps"
SIZE_DATA_FILE="./vault/data/size.yml"
TEMPLATE_FILE="./scripts/map-template.html"

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
        IMG_NAME=$(echo "$YAML" | yq -r ".images[$i].name")
        MAP=$(echo "$YAML" | yq -r ".images[$i].map // false")
        BG=$(echo "$YAML" | yq -r ".images[$i].background // \"white\"")
        DISPLAY=$(echo "$YAML" | yq -r ".images[$i].display // true") # Default to true
        FILE=$(echo "$YAML" | yq -r ".images[$i].file // false")     # Default to false
        PATHMD="_${MD_FILE#*_}"

        echo "Found image: $IMG_NAME (map: $MAP)"
        

        SRC_IMG_PATH="$SRC_IMAGE_DIR/$IMG_NAME"
        EXT="${IMG_NAME##*.}"
        IMG_BASE="${IMG_NAME%.*}"
        DEST_FOLDER="$DEST_IMAGE_DIR/$IMG_BASE"

        if [ ! -f "$SRC_IMG_PATH" ]; then
            echo "Image not found: $SRC_IMG_PATH"
            continue
        fi

        mkdir -p "$DEST_FOLDER"
        cp "$SRC_IMG_PATH" "$DEST_FOLDER/$IMG_NAME" # Always copy original image/file

        if [ "$DISPLAY" = "true" ]; then
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

            if [[ -d "$TILE_PATH" ]]; then
                echo "Skipping $IMG_NAME, tiles already exist."
            else
                echo "Processing $IMG_NAME..."

                # read WIDTH HEIGHT <<< $(identify -format "%w %h" "$SRC_IMG_PATH")
                WIDTH=$(vipsheader -f width "$SRC_IMG_PATH")
                HEIGHT=$(vipsheader -f height "$SRC_IMG_PATH")

                vips dzsave "$SRC_IMG_PATH" "$TILE_PATH" \
                    --layout google --centre --suffix .webp[Q=95,near_lossless=true] \
                    --tile-size 256 --vips-progress

                HTML_FILE="$MAPS_HTML_DIR/${IMG_BASE}.md"

                echo "Creating HTML viewer for $IMG_NAME at $HTML_FILE"

                # Use printf instead of echo to avoid quote issues
                printf '%s' "$TEMPLATE_HTML" \
                    | sed "s/__IMG_NAME__/$IMG_BASE/g" \
                    | sed "s/__WIDTH__/$WIDTH/g" \
                    | sed "s/__HEIGHT__/$HEIGHT/g" \
                    | sed "s/__BG__/$BG/g" \
                    | sed "s/__TITLE__/$(printf '%s\n' "$PAGE_TITLE" | sed 's/[&/\]/\\&/g')/g" \
                    | sed "s|__PATHMD__|$PATHMD|g" \
                    > "$HTML_FILE"

            fi
        fi

        echo "Processed: $IMG_NAME (map: $MAP)"
    done
done

echo "Aspect ratio data has been updated in $SIZE_DATA_FILE"