#!/bin/bash
# Install sample vCard contacts for a KDE Connect device
# Usage: bash install-sample-contacts.sh [device_id]
# Called by: setup-vm.sh or manually via serial
#
# Creates 12 contacts with varied data (multiple phone types, photos, nationalities)

set -euo pipefail

DEVICE_ID="${1:-}"
if [ -z "$DEVICE_ID" ]; then
    # Auto-detect last device (loopback appends _loopback suffix → sorts last)
    DEVICE_ID=$(su - neon -c '
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
        qdbus6 org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices 2>/dev/null
    ' | tail -1 || echo "")
fi

if [ -z "$DEVICE_ID" ]; then
    echo "ERROR: No device ID provided or detected"
    exit 1
fi

VCARD_DIR="/home/neon/.local/share/kpeoplevcard/kdeconnect-${DEVICE_ID}"
mkdir -p "$VCARD_DIR"

# ── Generate avatar photos as base64 PNG (32x32 solid-color squares) ──

PHOTO_DIR=$(mktemp -d)

python3 - "$PHOTO_DIR" << 'PYSCRIPT'
import struct, zlib, base64, sys, os

outdir = sys.argv[1]

def make_avatar_png(r, g, b, size=48):
    """Generate a solid-color PNG avatar, returns base64 string."""
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
    # Create a simple circle-ish pattern (rounded square)
    raw = b''
    center = size // 2
    radius = size // 2 - 2
    for y in range(size):
        row = b'\x00'  # filter byte
        for x in range(size):
            dx = x - center
            dy = y - center
            dist = (dx*dx + dy*dy) ** 0.5
            if dist <= radius:
                row += bytes([r, g, b])
            else:
                # Transparent-ish white background
                row += bytes([240, 240, 240])
        raw += row
    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return base64.b64encode(header + ihdr + idat + iend).decode()

# Generate colored avatars for contacts that have photos
avatars = {
    'jean':     (41, 128, 185),   # blue
    'marie':    (192, 57, 43),    # red
    'sophie':   (39, 174, 96),    # green
    'camille':  (142, 68, 173),   # purple
    'isabelle': (230, 126, 34),   # orange
    'emma':     (22, 160, 133),   # teal
    'alice':    (211, 84, 0),     # dark orange
}

for name, (r, g, b) in avatars.items():
    b64 = make_avatar_png(r, g, b)
    with open(os.path.join(outdir, f'{name}.b64'), 'w') as f:
        f.write(b64)

print(f"Generated {len(avatars)} avatar images")
PYSCRIPT

echo "  Generating contact avatars..."

# Helper: read base64 photo data
photo_b64() {
    local name="$1"
    local file="$PHOTO_DIR/${name}.b64"
    if [ -f "$file" ]; then
        cat "$file"
    fi
}

# ── Contact 1: Jean Dupont (FR, 2 numbers, photo) ──
PHOTO=$(photo_b64 jean)
cat > "$VCARD_DIR/contact01.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Jean Dupont
TEL;TYPE=CELL:+33612345678
TEL;TYPE=HOME:+33143210987
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# ── Contact 2: Marie Martin (FR, cell, photo) ──
PHOTO=$(photo_b64 marie)
cat > "$VCARD_DIR/contact02.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Marie Martin
TEL;TYPE=CELL:+33698765432
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# ── Contact 3: Pierre Bernard (FR, cell + work, no photo) ──
cat > "$VCARD_DIR/contact03.vcf" << 'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Pierre Bernard
TEL;TYPE=CELL:+33755443322
TEL;TYPE=WORK:+33145678901
END:VCARD
EOF

# ── Contact 4: Sophie Leroy (FR, cell, photo) ──
PHOTO=$(photo_b64 sophie)
cat > "$VCARD_DIR/contact04.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Sophie Leroy
TEL;TYPE=CELL:+33611223344
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# ── Contact 5: François Moreau (FR, cell + work, no photo) ──
cat > "$VCARD_DIR/contact05.vcf" << 'EOF'
BEGIN:VCARD
VERSION:3.0
FN:François Moreau
TEL;TYPE=CELL:+33677889900
TEL;TYPE=WORK:+33140556677
END:VCARD
EOF

# ── Contact 6: Camille Petit (FR, cell + work, photo) ──
PHOTO=$(photo_b64 camille)
cat > "$VCARD_DIR/contact06.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Camille Petit
TEL;TYPE=CELL:+33644556677
TEL;TYPE=WORK:+33155667788
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# ── Contact 7: Thomas Roux (FR, cell only, no photo) ──
cat > "$VCARD_DIR/contact07.vcf" << 'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Thomas Roux
TEL;TYPE=CELL:+33633221100
END:VCARD
EOF

# ── Contact 8: Isabelle Fournier (FR, cell + home, photo) ──
PHOTO=$(photo_b64 isabelle)
cat > "$VCARD_DIR/contact08.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Isabelle Fournier
TEL;TYPE=CELL:+33622113344
TEL;TYPE=HOME:+33148991122
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# ── Contact 9: Nicolas Garcia (ES, cell, no photo) ──
cat > "$VCARD_DIR/contact09.vcf" << 'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Nicolas Garcia
TEL;TYPE=CELL:+34612345678
END:VCARD
EOF

# ── Contact 10: Emma Schmidt (DE, cell + work, photo) ──
PHOTO=$(photo_b64 emma)
cat > "$VCARD_DIR/contact10.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Emma Schmidt
TEL;TYPE=CELL:+4915123456789
TEL;TYPE=WORK:+493012345678
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# ── Contact 11: Luca Rossi (IT, cell, no photo) ──
cat > "$VCARD_DIR/contact11.vcf" << 'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Luca Rossi
TEL;TYPE=CELL:+393312345678
END:VCARD
EOF

# ── Contact 12: Alice Dubois (FR, cell + work, photo) ──
PHOTO=$(photo_b64 alice)
cat > "$VCARD_DIR/contact12.vcf" << EOF
BEGIN:VCARD
VERSION:3.0
FN:Alice Dubois
TEL;TYPE=CELL:+33699887766
TEL;TYPE=WORK:+33156781234
PHOTO;ENCODING=b;TYPE=PNG:${PHOTO}
END:VCARD
EOF

# Clean up old contacts (from previous install) and temp files
rm -f "$VCARD_DIR"/contact[0-9].vcf 2>/dev/null || true
rm -rf "$PHOTO_DIR"

chown -R neon:neon "$VCARD_DIR"
TOTAL=$(ls "$VCARD_DIR"/*.vcf 2>/dev/null | wc -l)
echo "OK: $TOTAL sample contacts installed in $VCARD_DIR"
