#!/bin/bash
# Install pre-built KDE Connect with loopback backend enabled
# Uses pre-compiled binaries from vm/prebuilt/ (built via Docker on host)
#
# Usage: bash setup-loopback.sh
# Called by: setup-vm.sh (via serial console, runs as root)
#
# NOTE: KDE Neon live ISO — changes don't survive reboot.

set -euo pipefail

PREBUILT_DIR="/mnt/plasmoid/vm/prebuilt"
MARKER="/tmp/.loopback-installed"

# ── Skip if already installed this session ──

if [ -f "$MARKER" ]; then
    echo "  Loopback already installed this session. Skipping."
    exit 0
fi

echo "=== Setting up KDE Connect loopback backend ==="

# ── Step 1: Check pre-built binaries exist ──

if [ ! -d "$PREBUILT_DIR" ] || [ -z "$(ls "$PREBUILT_DIR"/*.so* 2>/dev/null)" ]; then
    echo "  ERROR: Pre-built binaries not found in $PREBUILT_DIR"
    echo "  Build them on the host: docker build -t kdeconnect-loopback vm/build-loopback/"
    echo "  Then extract: vm/build-loopback/extract.sh"
    exit 1
fi

echo "[1/3] Installing pre-built loopback binaries..."

# ── Step 2: Replace system binaries ──

# Find where kdeconnectd is installed
DAEMON_PATH=$(which kdeconnectd 2>/dev/null || find /usr -name kdeconnectd -type f 2>/dev/null | head -1)
if [ -z "$DAEMON_PATH" ]; then
    echo "  ERROR: kdeconnectd not found on system"
    exit 1
fi
DAEMON_DIR=$(dirname "$DAEMON_PATH")

# Find where libkdeconnectcore.so is installed
LIB_PATH=$(find /usr -name "libkdeconnectcore.so*" -type f 2>/dev/null | head -1)
if [ -z "$LIB_PATH" ]; then
    LIB_PATH=$(find /usr -name "libkdeconnectcore.so*" -type l 2>/dev/null | head -1)
fi
LIB_DIR=$(dirname "$LIB_PATH" 2>/dev/null || echo "/usr/lib/x86_64-linux-gnu")

echo "  Daemon: $DAEMON_PATH"
echo "  Lib dir: $LIB_DIR"

# Kill existing daemon
echo "[2/3] Stopping kdeconnectd..."
pkill -f kdeconnectd 2>/dev/null || true
sleep 1

# Backup originals
cp "$DAEMON_PATH" "${DAEMON_PATH}.orig" 2>/dev/null || true

# Copy pre-built binaries
if [ -f "$PREBUILT_DIR/kdeconnectd" ]; then
    cp "$PREBUILT_DIR/kdeconnectd" "$DAEMON_PATH"
    chmod +x "$DAEMON_PATH"
    echo "  Replaced kdeconnectd"
fi

# Copy libraries (all .so files)
for f in "$PREBUILT_DIR"/libkdeconnect*.so*; do
    [ -f "$f" ] || continue
    cp "$f" "$LIB_DIR/"
    echo "  Installed $(basename "$f") → $LIB_DIR/"
done

# Refresh library cache
ldconfig 2>/dev/null || true

# ── Step 3: Restart daemon ──

echo "[3/3] Starting kdeconnectd with loopback..."
su - neon -c '
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    export XDG_RUNTIME_DIR=/run/user/1000
    kdeconnectd &
' 2>/dev/null || {
    su - neon -c "
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
        export XDG_RUNTIME_DIR=/run/user/1000
        $DAEMON_PATH &
    " 2>/dev/null || true
}

sleep 3

# ── Verify loopback device ──

echo "Checking for loopback device..."
DEVICES=$(su - neon -c '
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    qdbus6 org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices 2>/dev/null
' || echo "")

if [ -z "$DEVICES" ]; then
    echo "  WARNING: No devices found. Checking daemon status..."
    su - neon -c '
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
        qdbus6 org.kde.kdeconnect /modules/kdeconnect 2>/dev/null | head -5
    ' || echo "  D-Bus service not available"
    touch "$MARKER"
    echo "=== Loopback installed (no device found) ==="
    exit 0
fi

echo "  Loopback device detected: $DEVICES"

# ── Auto-pair the loopback device ──

DEVICE_ID=$(echo "$DEVICES" | head -1)

# Validate device ID: alphanumeric, hyphens, underscores only (prevents shell injection)
if [[ ! "$DEVICE_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "  ERROR: Invalid device ID (contains unsafe characters): $DEVICE_ID" >&2
    exit 1
fi

echo "  Pairing with $DEVICE_ID..."

su - neon -c "
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/$DEVICE_ID org.kde.kdeconnect.device.requestPairing 2>/dev/null
"
sleep 2

IS_PAIRED=$(su - neon -c "
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/$DEVICE_ID org.kde.kdeconnect.device.isPaired 2>/dev/null
" || echo "false")

if [ "$IS_PAIRED" = "true" ]; then
    echo "  Paired successfully!"
else
    echo "  WARNING: Pairing may not have completed (isPaired=$IS_PAIRED)"
fi

touch "$MARKER"
echo "=== Loopback backend ready (device: $DEVICE_ID, paired: $IS_PAIRED) ==="
