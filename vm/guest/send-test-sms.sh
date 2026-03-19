#!/bin/bash
# Simulate incoming SMS notifications via loopback
# The patched sendnotifications plugin marks forwarded notifications as "silent",
# so they appear in NotificationsModel (badge) without creating KDE popup notifications
# (no feedback loop).
#
# Usage (inside VM as neon):
#   bash send-test-sms.sh                          # default test message
#   bash send-test-sms.sh "Marie Martin" "Salut!"  # custom sender + message
#   bash send-test-sms.sh clear                    # dismiss all notifications
#
# Usage (from host via serial):
#   vm_serial "su - neon -c 'bash /mnt/plasmoid/vm/guest/send-test-sms.sh'"

set -euo pipefail

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/1000/bus}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

# Find device ID
DEVICE_ID=$(kdeconnect-cli -l 2>/dev/null | grep -oP '[a-f0-9_]+_loopback' | head -1)
if [ -z "$DEVICE_ID" ]; then
    echo "ERROR: No loopback device found"
    exit 1
fi

DEVICE_PATH="/modules/kdeconnect/devices/$DEVICE_ID"

# Clear mode: dismiss all notifications
if [ "${1:-}" = "clear" ]; then
    NOTIF_PATH="$DEVICE_PATH/notifications"
    NOTIFS=$(qdbus6 org.kde.kdeconnect "$NOTIF_PATH" \
        org.kde.kdeconnect.device.notifications.activeNotifications 2>/dev/null || echo "")
    COUNT=0
    for id in $NOTIFS; do
        qdbus6 org.kde.kdeconnect "${NOTIF_PATH}/${id}" \
            org.kde.kdeconnect.device.notifications.notification.dismiss 2>/dev/null || true
        COUNT=$((COUNT + 1))
    done
    echo "Dismissed $COUNT notifications"
    exit 0
fi

SENDER="${1:-Jean Dupont}"
MESSAGE="${2:-Salut, tu es libre ce soir ?}"

# Ensure sendnotifications plugin is enabled
if ! qdbus6 org.kde.kdeconnect $DEVICE_PATH \
    org.kde.kdeconnect.device.loadedPlugins 2>/dev/null | grep -q sendnotifications; then
    qdbus6 org.kde.kdeconnect $DEVICE_PATH \
        org.kde.kdeconnect.device.setPluginEnabled kdeconnect_sendnotifications true 2>/dev/null
    qdbus6 org.kde.kdeconnect $DEVICE_PATH \
        org.kde.kdeconnect.device.reloadPlugins 2>/dev/null
    sleep 1
fi

# Send the test notification via freedesktop Notifications
# The patched sendnotifications plugin forwards it via loopback with silent=true,
# so it appears in NotificationsModel (badge) but NOT as a KDE popup (no feedback loop)
echo "Sending: $SENDER → $MESSAGE"
gdbus call -e \
    -d org.freedesktop.Notifications \
    -o /org/freedesktop/Notifications \
    -m org.freedesktop.Notifications.Notify \
    -- "Messages" 0 "dialog-information" \
    "$SENDER" "$MESSAGE" \
    "[]" "{}" -1 \
    > /dev/null 2>&1

sleep 1
echo "OK: notification sent (silent mode — badge only, no KDE popup)"
