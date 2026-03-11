#!/bin/bash
# Compile .po translation files into binary .mo files for KDE Plasma.
# Adapted for Plasma 6 (metadata.json instead of metadata.desktop)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$DIR/.." && pwd)"

# Read plugin ID from metadata.json (Plasma 6)
plasmoidName=$(python3 -c "import json; print(json.load(open('$PROJECT_DIR/metadata.json'))['KPlugin']['Id'])")
projectName="plasma_applet_${plasmoidName}"

if [ -z "$plasmoidName" ]; then
    echo "[build] Error: Couldn't read plasmoidName from metadata.json"
    exit 1
fi

echo "[build] Compiling translations for $projectName..."

catalogs=$(find "$DIR" -name '*.po' | sort)
count=0
for cat in $catalogs; do
    catLocale=$(basename "${cat%.*}")
    if ! msgfmt -o "$DIR/${catLocale}.mo" "$cat"; then
        echo "[build] Error compiling $cat" >&2
        if [ "${CI:-}" = "true" ]; then exit 1; fi
        continue
    fi

    installPath="$PROJECT_DIR/contents/locale/${catLocale}/LC_MESSAGES/${projectName}.mo"
    mkdir -p "$(dirname "$installPath")"
    mv "$DIR/${catLocale}.mo" "$installPath"
    echo "[build] ${catLocale} → ${installPath}"
    count=$((count + 1))
done

echo "[build] Done: $count locale(s) compiled."
