#!/bin/bash
# Validate plasmoid package structure and metadata.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check required files
for f in metadata.json contents/ui/main.qml contents/ui/configGeneral.qml contents/config/main.xml contents/config/config.qml; do
    if [ ! -f "$PROJECT_DIR/$f" ]; then
        echo "ERROR: Missing required file: $f" >&2
        exit 1
    fi
done

# Validate metadata.json
python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    meta = json.load(f)
plugin = meta.get('KPlugin', {})
required = ['Id', 'Name', 'Version', 'License']
missing = [k for k in required if k not in plugin]
if missing:
    print(f'ERROR: Missing KPlugin fields: {missing}', file=sys.stderr)
    sys.exit(1)
if meta.get('KPackageStructure') != 'Plasma/Applet':
    print('ERROR: KPackageStructure must be Plasma/Applet', file=sys.stderr)
    sys.exit(1)
print(f'Plugin: {plugin[\"Id\"]} v{plugin[\"Version\"]}')
" "$PROJECT_DIR/metadata.json"

echo "Package structure validated."
