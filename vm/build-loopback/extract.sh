#!/bin/bash
# Extract pre-built loopback binaries from Docker image
# Usage: bash vm/build-loopback/extract.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$(dirname "$SCRIPT_DIR")/prebuilt"
IMAGE="kdeconnect-loopback"

echo "Extracting loopback binaries from $IMAGE..."
mkdir -p "$OUTPUT_DIR"

# Create temp container and copy files
CONTAINER=$(docker create "$IMAGE" /bin/true)
docker cp "$CONTAINER:/output/." "$OUTPUT_DIR/"
docker rm "$CONTAINER" >/dev/null

echo "Extracted to $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR/"
echo "Done. Run setup-loopback.sh in the VM to install."
