#!/bin/bash
# Apply demo configuration to the KDE Connect SMS plasmoid
# Pre-configures device name and country code for testing
#
# Usage: bash demo-config.sh
# Called by: setup-vm.sh (via serial console, runs as root)
#
# Requires: plasmoid already added to panel (add-to-panel.sh)

set -euo pipefail

PLUGIN_ID="com.comexpertise.plasma.kdeconnectsms"
CONFIG_FILE="/home/neon/.config/plasma-org.kde.plasma.desktop-appletsrc"

# ── Find the applet's config group ──────────────────────────────
# The config file has INI-style sections like:
#   [Containments][2][Applets][15]
#   plugin=com.comexpertise.plasma.kdeconnectsms
# We need the group path segments to build kwriteconfig6 --group flags.

find_applet_group() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERROR: Config file not found: $CONFIG_FILE" >&2
        return 1
    fi

    local current_group=""
    while IFS= read -r line; do
        # Track current INI group
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            current_group="${BASH_REMATCH[1]}"
        fi
        # Look for our plugin ID
        if [[ "$line" == "plugin=$PLUGIN_ID" ]] && [[ -n "$current_group" ]]; then
            echo "$current_group"
            return 0
        fi
    done < "$CONFIG_FILE"

    echo "ERROR: Applet $PLUGIN_ID not found in $CONFIG_FILE" >&2
    return 1
}

echo "  Finding plasmoid config group..."
APPLET_GROUP=$(find_applet_group)

echo "  Applet group: [$APPLET_GROUP]"

# Build --group flags for kwriteconfig6
# Input: "Containments][2][Applets][15" → segments: Containments, 2, Applets, 15
# We append Configuration and General for the config subgroup
build_group_flags() {
    local group_str="$1"
    local flags=()
    # Split on "][" to get individual group segments
    IFS=']' read -ra parts <<< "$group_str"
    for part in "${parts[@]}"; do
        # Remove leading "["
        part="${part#\[}"
        if [ -n "$part" ]; then
            flags+=("--group" "$part")
        fi
    done
    # Append Configuration/General subgroup
    flags+=("--group" "Configuration" "--group" "General")
    echo "${flags[@]}"
}

GROUP_FLAGS=$(build_group_flags "$APPLET_GROUP")

# Helper: write a config key using kwriteconfig6
write_config() {
    local key="$1"
    local value="$2"
    # shellcheck disable=SC2086
    kwriteconfig6 --file "$CONFIG_FILE" $GROUP_FLAGS --key "$key" "$value"
}

# ── Demo configuration ────────────────────────────────────────

# ── Auto-detect device (loopback or mock) ────────────────────

# Validate device ID: alphanumeric, hyphens, underscores only (prevents shell injection)
validate_device_id() {
    local id="$1"
    if [[ ! "$id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid device ID (contains unsafe characters): $id" >&2
        return 1
    fi
}

DEVICE_ID="${DEMO_DEVICE_ID:-}"
DEVICE_NAME="${DEMO_DEVICE_NAME:-}"

if [ -z "$DEVICE_ID" ]; then
    # Try to detect the first paired KDE Connect device
    DEVICE_ID=$(su - neon -c '
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
        qdbus6 org.kde.kdeconnect /modules/kdeconnect org.kde.kdeconnect.daemon.devices 2>/dev/null
    ' | head -1 || echo "")

    if [ -n "$DEVICE_ID" ]; then
        validate_device_id "$DEVICE_ID" || exit 1
        DEVICE_NAME=$(su - neon -c "
            export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
            qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/$DEVICE_ID org.kde.kdeconnect.device.name 2>/dev/null
        " || echo "Galaxy S25")
    else
        # Fallback to mock device
        DEVICE_ID="mock_test_phone_0001"
        DEVICE_NAME="Test Phone"
    fi
fi

validate_device_id "$DEVICE_ID" || exit 1

echo "  Writing demo configuration..."

write_config "defaultDeviceId" "$DEVICE_ID"
write_config "defaultDeviceName" "$DEVICE_NAME"
write_config "defaultCountry" "FR"
write_config "speakerBeep" "false"

echo "  Demo config applied:"
echo "    - Device ID: $DEVICE_ID"
echo "    - Device name: $DEVICE_NAME"
echo "    - Country: FR (France)"
echo "    - Speaker beep: disabled"
