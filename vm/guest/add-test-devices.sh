#!/bin/bash
# Add fake paired devices to KDE Connect config for testing the device switcher.
# These devices appear as "paired but not reachable" in DevicesModel.
#
# Usage (inside VM as root): bash add-test-devices.sh
# Usage (from host via serial): vm_serial "bash /mnt/plasmoid/vm/guest/add-test-devices.sh"

set -euo pipefail

KDECONNECT_DIR="/home/neon/.config/kdeconnect"
TRUSTED="$KDECONNECT_DIR/trusted_devices"

if [ ! -f "$TRUSTED" ]; then
    echo "ERROR: trusted_devices not found — run setup-vm.sh first"
    exit 1
fi

add_device() {
    local dev_id="$1"
    local dev_name="$2"
    local dev_type="${3:-phone}"

    # Skip if already present
    if grep -q "\\[$dev_id\\]" "$TRUSTED" 2>/dev/null; then
        echo "  $dev_name ($dev_id) — already exists, skipping"
        return
    fi

    # Generate a self-signed certificate
    local cert
    cert=$(openssl req -x509 -newkey ec \
        -pkeyopt ec_paramgen_curve:prime256v1 \
        -nodes -subj "/CN=$dev_id/O=KDE/OU=KDE Connect" \
        -days 3650 -keyout /dev/null 2>/dev/null \
        | sed ':a;N;$!ba;s/\n/\\n/g')

    # Create device config directory
    mkdir -p "$KDECONNECT_DIR/$dev_id"

    # Append to trusted_devices
    cat >> "$TRUSTED" << DEVEOF

[$dev_id]
certificate="$cert"
name=$dev_name
protocolVersion=8
type=$dev_type
DEVEOF

    echo "  $dev_name ($dev_id) — added"
}

echo "Adding test devices..."

add_device "a1b2c3d4e5f6_iphone15" "iPhone 15" "phone"
add_device "f9e8d7c6b5a4_pixel8"   "Pixel 8"   "phone"

chown -R neon:neon "$KDECONNECT_DIR"

# Restart kdeconnectd to pick up changes
echo "Restarting kdeconnectd..."
pkill -f kdeconnectd 2>/dev/null || true
sleep 1
su - neon -c '
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    export XDG_RUNTIME_DIR=/run/user/1000
    export WAYLAND_DISPLAY=wayland-0
    kdeconnectd &
' 2>/dev/null
sleep 3

# Verify
DEVICE_COUNT=$(su - neon -c '
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    kdeconnect-cli -l 2>/dev/null | grep -c "^-" || echo 0
')
echo "Done — $DEVICE_COUNT device(s) visible in KDE Connect"
