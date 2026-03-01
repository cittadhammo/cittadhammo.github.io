#!/usr/bin/env bash
set -euo pipefail

CONTENT_DIR="${1:-./vault/content}"
CONFIG_FILE="${2:-./_config.yml}"
AREAS_FILE="${3:-./vault/data/areas.yml}"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq not found in PATH (mikefarah/yq required)."
  exit 1
fi

if [ ! -d "$CONTENT_DIR" ]; then
  echo "Content directory not found: $CONTENT_DIR"
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

if [ ! -f "$AREAS_FILE" ]; then
  echo "Areas file not found: $AREAS_FILE"
  exit 1
fi

mapfile -t COLLECTIONS < <(
  find "$CONTENT_DIR" -maxdepth 1 -mindepth 1 -type d -name "_*" -printf "%f\n" \
    | sed 's/^_//' \
    | grep -v '^archive$' \
    | sort
)

if [ "${#COLLECTIONS[@]}" -eq 0 ]; then
  echo "No collection folders found in $CONTENT_DIR (expected names like _charts)."
  exit 1
fi

TMP_OLD_CONFIG="$(mktemp)"
TMP_EXTRA_DEFAULTS="$(mktemp)"
TMP_NEW_AREAS="$(mktemp)"
trap 'rm -f "$TMP_OLD_CONFIG" "$TMP_EXTRA_DEFAULTS" "$TMP_NEW_AREAS"' EXIT

cp "$CONFIG_FILE" "$TMP_OLD_CONFIG"

# Keep non-generated defaults from old config (page defaults or custom scoped defaults).
yq '
  .defaults
  | map(
      select(
        (.scope.path != "")
        or (.scope.type == null)
        or (.values.layout != "item")
      )
    )
' "$TMP_OLD_CONFIG" > "$TMP_EXTRA_DEFAULTS"

# Rebuild collections from content folders (preserving per-collection extra fields if present).
yq -i '.collections = {}' "$CONFIG_FILE"
for name in "${COLLECTIONS[@]}"; do
  yq -i "
    .collections.\"$name\" = (
      (load(\"$TMP_OLD_CONFIG\").collections.\"$name\" // {})
      * {\"output\": true, \"sort_by\": \"order\"}
    )
  " "$CONFIG_FILE"
done

# Rebuild generated item defaults, then append kept non-generated defaults.
yq -i '.defaults = []' "$CONFIG_FILE"
for name in "${COLLECTIONS[@]}"; do
  yq -i ".defaults += [{\"scope\": {\"path\": \"\", \"type\": \"$name\"}, \"values\": {\"layout\": \"item\"}}]" "$CONFIG_FILE"
done
yq -i ".defaults += load(\"$TMP_EXTRA_DEFAULTS\")" "$CONFIG_FILE"

# Rebuild areas in collection-folder order, preserving existing entries when present.
echo '[]' > "$TMP_NEW_AREAS"
for name in "${COLLECTIONS[@]}"; do
  yq -i "
    . += [
      (
        (load(\"$AREAS_FILE\")[] | select(.name == \"$name\"))
        // {\"name\": \"$name\", \"categories\": []}
      )
    ]
  " "$TMP_NEW_AREAS"
done
mv "$TMP_NEW_AREAS" "$AREAS_FILE"

echo "Synced structure from $CONTENT_DIR"
echo "Updated: $CONFIG_FILE (collections + defaults)"
echo "Updated: $AREAS_FILE (area entries)"
echo "Collections: ${COLLECTIONS[*]}"
