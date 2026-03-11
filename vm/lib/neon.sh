#!/bin/bash
# Helper for running commands as the neon user inside the VM
#
# Usage:
#   source "$(dirname "$0")/lib/neon.sh"
#
# Provides (via serial.sh):
#   SERIAL_SOCK, vm_serial(), check_serial_sock()
# Provides:
#   vm_as_neon() — run command as neon user with D-Bus access

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/serial.sh"

# Run command as neon user inside VM (serial shell runs as root)
vm_as_neon() {
    vm_serial "su - neon -c 'DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 QT_WAYLAND_RECONNECT=1 $1'"
}
