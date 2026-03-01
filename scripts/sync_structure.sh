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

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

mapfile -t EXISTING_CONFIG_COLLECTIONS < <(yq -r '.collections | to_entries | .[].key' "$CONFIG_FILE" 2>/dev/null || true)
mapfile -t EXISTING_AREA_ORDER < <(yq -r '.[] | .name' "$AREAS_FILE" 2>/dev/null || true)

# Preserve existing order; append newly discovered folders at the end.
ORDERED_CONFIG_COLLECTIONS=()
for name in "${EXISTING_CONFIG_COLLECTIONS[@]}"; do
  if contains "$name" "${COLLECTIONS[@]}"; then
    ORDERED_CONFIG_COLLECTIONS+=("$name")
  fi
done
for name in "${COLLECTIONS[@]}"; do
  if ! contains "$name" "${ORDERED_CONFIG_COLLECTIONS[@]}"; then
    ORDERED_CONFIG_COLLECTIONS+=("$name")
  fi
done

ORDERED_AREAS=()
for name in "${EXISTING_AREA_ORDER[@]}"; do
  if contains "$name" "${COLLECTIONS[@]}"; then
    ORDERED_AREAS+=("$name")
  fi
done
for name in "${COLLECTIONS[@]}"; do
  if ! contains "$name" "${ORDERED_AREAS[@]}"; then
    ORDERED_AREAS+=("$name")
  fi
done

TMP_OLD_CONFIG="$(mktemp)"
TMP_OLD_AREAS="$(mktemp)"
TMP_EXTRA_DEFAULTS="$(mktemp)"
TMP_NEW_AREAS="$(mktemp)"
TMP_CATS="$(mktemp)"
TMP_PAGES="$(mktemp)"
trap 'rm -f "$TMP_OLD_CONFIG" "$TMP_OLD_AREAS" "$TMP_EXTRA_DEFAULTS" "$TMP_NEW_AREAS" "$TMP_CATS" "$TMP_PAGES"' EXIT

cp "$CONFIG_FILE" "$TMP_OLD_CONFIG"
cp "$AREAS_FILE" "$TMP_OLD_AREAS"

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
for name in "${ORDERED_CONFIG_COLLECTIONS[@]}"; do
  yq -i "
    .collections.\"$name\" = (
      (load(\"$TMP_OLD_CONFIG\").collections.\"$name\" // {})
      * {\"output\": true, \"sort_by\": \"order\"}
    )
  " "$CONFIG_FILE"
done

# Rebuild generated item defaults, then append kept non-generated defaults.
yq -i '.defaults = []' "$CONFIG_FILE"
for name in "${ORDERED_CONFIG_COLLECTIONS[@]}"; do
  yq -i ".defaults += [{\"scope\": {\"path\": \"\", \"type\": \"$name\"}, \"values\": {\"layout\": \"item\"}}]" "$CONFIG_FILE"
done
yq -i ".defaults += load(\"$TMP_EXTRA_DEFAULTS\")" "$CONFIG_FILE"

# Rebuild areas in collection-folder order, preserving existing entries when present.
echo '[]' > "$TMP_NEW_AREAS"
for name in "${ORDERED_AREAS[@]}"; do
  mapfile -t CATEGORIES < <(
    find "$CONTENT_DIR/_$name" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" \
      | grep -v '^\.' \
      | sort
  )

  echo '[]' > "$TMP_CATS"
  for cat in "${CATEGORIES[@]}"; do
    yq -i ". += [{\"name\": \"$cat\"}]" "$TMP_CATS"
  done

  mapfile -t PAGES < <(
    find "$CONTENT_DIR/_$name" -maxdepth 1 -mindepth 1 -type f -name "*.md" -printf "%f\n" \
      | sed 's/\.md$//' \
      | sort
  )

  echo '[]' > "$TMP_PAGES"
  for page in "${PAGES[@]}"; do
    yq -i ". += [{\"name\": \"$page\"}]" "$TMP_PAGES"
  done

  yq -i ". += [((load(\"$TMP_OLD_AREAS\")[] | select(.name == \"$name\")) // {\"name\": \"$name\"})]" "$TMP_NEW_AREAS"
  yq -i "(.[] | select(.name == \"$name\")).categories = load(\"$TMP_CATS\")" "$TMP_NEW_AREAS"
  yq -i "(.[] | select(.name == \"$name\")).pages = load(\"$TMP_PAGES\")" "$TMP_NEW_AREAS"
done
mv "$TMP_NEW_AREAS" "$AREAS_FILE"

echo "Synced structure from $CONTENT_DIR"
echo "Updated: $CONFIG_FILE (collections + defaults)"
echo "Updated: $AREAS_FILE (area entries)"
echo "Collections (config order): ${ORDERED_CONFIG_COLLECTIONS[*]}"
echo "Areas (areas.yml order): ${ORDERED_AREAS[*]}"
