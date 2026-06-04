#!/bin/bash
# scripts/flatten_png.sh
# Usage: ./scripts/flatten_png.sh <image_path_or_name> [background_color]
# background_color defaults to "255,255,255" (white)

if [ -z "$1" ]; then
    echo "Usage: make flatten-png FILE=<image_name> [BG='255 255 255']"
    exit 1
fi

SRC_DIR="./vault/assets/images"
FILE_INPUT="$1"
BG="${2:-255 255 255}"

# Try to resolve file path
if [ -f "$FILE_INPUT" ]; then
    SRC="$FILE_INPUT"
elif [ -f "$SRC_DIR/$FILE_INPUT" ]; then
    SRC="$SRC_DIR/$FILE_INPUT"
else
    # Try fuzzy match
    MATCH=$(find "$SRC_DIR" -maxdepth 1 -type f -iname "$FILE_INPUT*" | head -n 1)
    if [ -n "$MATCH" ]; then
        SRC="$MATCH"
    else
        echo "Error: File not found: $FILE_INPUT"
        exit 1
    fi
fi

EXT="${SRC##*.}"
BASE="${SRC%.*}"
TMP="${BASE}.tmp.${EXT}"

# Check if it has an alpha channel
BANDS=$(vipsheader -f bands "$SRC" 2>/dev/null)

if [ "$BANDS" = "4" ]; then
    echo "Flattening $SRC to background [$BG]..."
    # vips flatten requires comma separated values or space separated?
    # Usually space separated in CLI, but the script generate_assets.sh uses r,g,b with commas?
    # Actually vips flatten --background "255 255 255"
    
    VIPS_BG=$(echo "$BG" | sed 's/ /,/g')
    
    if vips flatten "$SRC" "$TMP" --background "$VIPS_BG"; then
        mv "$TMP" "$SRC"
        echo "Successfully flattened $SRC"
    else
        echo "Error flattening $SRC"
        rm -f "$TMP"
        exit 1
    fi
else
    echo "$SRC does not have an alpha channel (bands=$BANDS). Skipping."
fi
