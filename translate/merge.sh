#!/bin/bash
# Extract translatable strings from QML/JS sources into template.pot
# Adapted for Plasma 6 (metadata.json instead of metadata.desktop)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$DIR/.." && pwd)"

# Read plugin info from metadata.json (Plasma 6)
plasmoidName=$(python3 -c "import json; print(json.load(open('$PROJECT_DIR/metadata.json'))['KPlugin']['Id'])")
widgetName="${plasmoidName##*.}"
bugAddress=$(python3 -c "import json; print(json.load(open('$PROJECT_DIR/metadata.json'))['KPlugin'].get('Website', ''))")
projectName="plasma_applet_${plasmoidName}"

if [ -z "$plasmoidName" ]; then
    echo "[merge] Error: Couldn't read plasmoidName from metadata.json"
    exit 1
fi

echo "[merge] Project: $projectName"
echo "[merge] Extracting messages..."

# Find all translatable source files (relative paths, exclude non-source dirs)
(cd "$PROJECT_DIR" && find contents -name '*.qml' -o -name '*.js' | sort) > "$DIR/infiles.list"

xgettext \
    --files-from="$DIR/infiles.list" \
    --from-code=UTF-8 \
    --width=400 \
    --add-location=file \
    -C -kde -ci18n \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    -ktr2i18n:1 -kI18N_NOOP:1 -kI18N_NOOP2:1c,2 \
    -kN_:1 -kaliasLocale -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 \
    --package-name="$widgetName" \
    --msgid-bugs-address="$bugAddress" \
    -D "$PROJECT_DIR" \
    -o "$DIR/template.pot.new" \
    || { echo "[merge] Error calling xgettext. Aborting."; exit 1; }

# Fix charset, header, and format flags
# Remove c-format flags: KDE i18n uses %1 style (not C-style %s/%d)
sed -i '/#, c-format/d' "$DIR/template.pot.new"
sed -i 's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' "$DIR/template.pot.new"
sed -i 's/# SOME DESCRIPTIVE TITLE./# Translation of KDE Connect SMS/' "$DIR/template.pot.new"
sed -i "s/# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER/# Copyright (C) $(date +%Y) David DIVERRES/" "$DIR/template.pot.new"

if [ -f "$DIR/template.pot" ]; then
    newPotDate=$(grep "POT-Creation-Date:" "$DIR/template.pot.new" | sed 's/.\{3\}$//')
    oldPotDate=$(grep "POT-Creation-Date:" "$DIR/template.pot" | sed 's/.\{3\}$//')
    sed -i "s|${newPotDate}|${oldPotDate}|" "$DIR/template.pot.new"
    changes=$(diff "$DIR/template.pot" "$DIR/template.pot.new" || true)
    if [ -n "$changes" ]; then
        sed -i "s|${oldPotDate}|${newPotDate}|" "$DIR/template.pot.new"
        mv "$DIR/template.pot.new" "$DIR/template.pot"
        echo "[merge] template.pot updated."
    else
        rm "$DIR/template.pot.new"
        echo "[merge] No changes in template.pot."
    fi
else
    mv "$DIR/template.pot.new" "$DIR/template.pot"
    echo "[merge] template.pot created."
fi

# Update existing .po files with new strings
catalogs=$(find "$DIR" -name '*.po' | sort)
for cat in $catalogs; do
    echo "[merge] Updating $(basename "$cat")..."
    msgmerge --no-fuzzy-matching --backup=none --update "$cat" "$DIR/template.pot"
done

rm -f "$DIR/infiles.list"
echo "[merge] Done."
