#!/usr/bin/env bash
set -euo pipefail

CONTENT_DIR="${1:-./vault/content}"
CONFIG_FILE="${2:-./_config.yml}"
AREAS_FILE="${3:-./vault/data/areas.yml}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync_structure.sh"

if [ ! -f "$SYNC_SCRIPT" ]; then
  echo "Sync script not found: $SYNC_SCRIPT"
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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EXPECTED_CONFIG="$TMP_DIR/config.expected.yml"
EXPECTED_AREAS="$TMP_DIR/areas.expected.yml"

cp "$CONFIG_FILE" "$EXPECTED_CONFIG"
cp "$AREAS_FILE" "$EXPECTED_AREAS"

bash "$SYNC_SCRIPT" "$CONTENT_DIR" "$EXPECTED_CONFIG" "$EXPECTED_AREAS" >/dev/null

status=0

if ! diff -u "$CONFIG_FILE" "$EXPECTED_CONFIG" >/dev/null; then
  echo "Out of sync: $CONFIG_FILE"
  diff -u "$CONFIG_FILE" "$EXPECTED_CONFIG" || true
  status=1
fi

if ! diff -u "$AREAS_FILE" "$EXPECTED_AREAS" >/dev/null; then
  echo "Out of sync: $AREAS_FILE"
  diff -u "$AREAS_FILE" "$EXPECTED_AREAS" || true
  status=1
fi

if [ "$status" -ne 0 ]; then
  echo ""
  echo "Structure drift detected. Run:"
  echo "  make structure"
  exit 1
fi

echo "Structure is in sync:"
echo "  - $CONFIG_FILE"
echo "  - $AREAS_FILE"
