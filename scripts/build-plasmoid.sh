#!/bin/bash
# Build the .plasmoid archive (zip) for distribution.
# Usage: scripts/build-plasmoid.sh [output-dir]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Read plugin ID and version from metadata.json
PLUGIN_ID=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['KPlugin']['Id'])" "$PROJECT_DIR/metadata.json")
VERSION=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['KPlugin']['Version'])" "$PROJECT_DIR/metadata.json")

# Sanitize: reject values containing path separators or shell-hostile characters
if [[ "$PLUGIN_ID" =~ [/\\] ]] || [[ "$VERSION" =~ [/\\] ]]; then
    echo "ERROR: Plugin ID or Version contains path separators" >&2
    exit 1
fi

OUTPUT_DIR="${1:-$PROJECT_DIR/build}"
mkdir -p "$OUTPUT_DIR"

ARCHIVE_NAME="${PLUGIN_ID}-${VERSION}.plasmoid"
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"

# Compile translations if translate/build.sh exists and .po files are present
if [ -x "$PROJECT_DIR/translate/build.sh" ] && ls "$PROJECT_DIR"/translate/*.po &>/dev/null; then
    echo "Compiling translations..."
    # Clean stale .mo files before recompiling
    rm -rf "$PROJECT_DIR/contents/locale"
    bash "$PROJECT_DIR/translate/build.sh"
fi

# Touch QML/JS files so zip timestamps are fresh — forces Qt QML cache
# invalidation when kpackage extracts the archive (avoids stale UI after update)
find "$PROJECT_DIR/contents" "$PROJECT_DIR/metadata.json" -type f \
    \( -name "*.qml" -o -name "*.js" -o -name "metadata.json" \) \
    -exec touch {} +

# Remove previous build if present
rm -f "$ARCHIVE_PATH"

# Create zip from project root, including only runtime files
cd "$PROJECT_DIR"
zip -r "$ARCHIVE_PATH" \
    metadata.json \
    contents/ \
    -x "*.qmlc" "*.jsc"

echo "Built: $ARCHIVE_PATH"
echo "Size: $(du -h "$ARCHIVE_PATH" | cut -f1)"
