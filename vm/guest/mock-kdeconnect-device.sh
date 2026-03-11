#!/bin/bash
# Create a mock KDE Connect device for testing
# Installs a wrapper script that makes qdbus6 return a fake device
# for KDE Connect D-Bus calls, while passing through other commands.
#
# Usage: bash mock-kdeconnect-device.sh
# Called by: setup-vm.sh (via serial console, runs as root)

set -euo pipefail

MOCK_DEVICE_ID="mock_test_phone_0001"
MOCK_DEVICE_NAME="Test Phone"
REAL_QDBUS="/usr/bin/qdbus6"
WRAPPER="/usr/local/bin/qdbus6"

# ── Create wrapper script ──

cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/bin/bash
# Mock wrapper for qdbus6 — intercepts KDE Connect D-Bus calls
# to inject a fake test device. All other calls pass through.

REAL_QDBUS="/usr/bin/qdbus6"
MOCK_ID="mock_test_phone_0001"
MOCK_NAME="Test Phone"
KDECONNECT_SVC="org.kde.kdeconnect"
DEVICE_PATH="/modules/kdeconnect/devices/$MOCK_ID"

# Detect KDE Connect deviceNames call
if [[ "${*}" == *"$KDECONNECT_SVC"*"deviceNames"* ]]; then
    # Get real output
    real_output=$("$REAL_QDBUS" "$@" 2>/dev/null) || true

    if [[ -n "$real_output" && "$real_output" != *"{}"* ]]; then
        # Inject mock device into existing map
        # Input: [Argument: a{ss} {"id1" = "name1"}]
        # Add our entry before the closing }
        echo "$real_output" | sed "s/}/, \"$MOCK_ID\" = \"$MOCK_NAME\"}/"
    else
        echo "[Argument: a{ss} {\"$MOCK_ID\" = \"$MOCK_NAME\"}]"
    fi
    exit 0
fi

# Detect SMS send to mock device
if [[ "${*}" == *"$DEVICE_PATH"*"sendWithoutConversation"* ]]; then
    echo "Mock: SMS sent successfully (simulated)" >&2
    exit 0
fi

# Detect contacts sync to mock device
if [[ "${*}" == *"$DEVICE_PATH"*"synchronizeRemoteWithLocal"* ]]; then
    echo "Mock: Contact sync triggered (simulated)" >&2
    exit 0
fi

# Pass through to real qdbus6
exec "$REAL_QDBUS" "$@"
WRAPPER_EOF

chmod +x "$WRAPPER"

# ── Create sample vCard contacts ──

NEON_HOME="/home/neon"
VCARD_DIR="$NEON_HOME/.local/share/kpeoplevcard/kdeconnect-$MOCK_DEVICE_ID"
mkdir -p "$VCARD_DIR"

cat > "$VCARD_DIR/contact1.vcf" << 'VCARD_EOF'
BEGIN:VCARD
VERSION:3.0
FN:Jean Dupont
TEL;TYPE=CELL:+33612345678
TEL;TYPE=HOME:+33143210987
END:VCARD
VCARD_EOF

cat > "$VCARD_DIR/contact2.vcf" << 'VCARD_EOF'
BEGIN:VCARD
VERSION:3.0
FN:Marie Martin
TEL;TYPE=CELL:+33698765432
END:VCARD
VCARD_EOF

cat > "$VCARD_DIR/contact3.vcf" << 'VCARD_EOF'
BEGIN:VCARD
VERSION:3.0
FN:Pierre Bernard
TEL;TYPE=CELL:+33755443322
TEL;TYPE=WORK:+33145678901
END:VCARD
VCARD_EOF

cat > "$VCARD_DIR/contact4.vcf" << 'VCARD_EOF'
BEGIN:VCARD
VERSION:3.0
FN:Sophie Laurent
TEL;TYPE=CELL:+33622334455
END:VCARD
VCARD_EOF

chown -R neon:neon "$NEON_HOME/.local/share/kpeoplevcard"

echo "  Mock device installed:"
echo "    - Device ID: $MOCK_DEVICE_ID"
echo "    - Device name: $MOCK_DEVICE_NAME"
echo "    - Wrapper: $WRAPPER (overrides $REAL_QDBUS)"
echo "    - qdbus6 deviceNames → includes mock device"
echo "    - SMS to mock device → simulated success"
echo "    - Contacts sync → simulated success"
echo "    - Sample contacts: 4 vCards in $VCARD_DIR"
