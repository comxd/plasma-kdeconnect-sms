#!/bin/bash
# Stop the VM for this project only (does not affect other project VMs)
#
# Usage:
#   ./vm/stop-vm.sh          # graceful stop via QEMU monitor
#   ./vm/stop-vm.sh --force  # kill the process immediately

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

export VM_NAME="${VM_NAME:-$(sed -n 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PROJECT_DIR/metadata.json" 2>/dev/null)}"
if [ -z "$VM_NAME" ]; then
    echo "ERROR: Could not determine VM_NAME — no \"Id\" field in metadata.json"
    exit 1
fi

MONITOR_SOCK="/tmp/${VM_NAME}-vm-monitor.sock"
SERIAL_SOCK="/tmp/${VM_NAME}-vm-serial.sock"

if [ "${1:-}" = "--force" ]; then
    # Kill by matching the QEMU process name
    pkill -f "qemu-system.*${VM_NAME}-vm" 2>/dev/null && echo "VM killed (force)" || echo "No VM running"
else
    # Graceful shutdown via QEMU monitor
    if [ -S "$MONITOR_SOCK" ]; then
        (echo "quit"; sleep 1) | socat - UNIX:"$MONITOR_SOCK" 2>/dev/null
        echo "VM stopped (graceful)"
    else
        echo "No VM running (monitor socket not found at $MONITOR_SOCK)"
        exit 0
    fi
fi

# Clean up sockets
sleep 2
rm -f "$SERIAL_SOCK" "$MONITOR_SOCK" 2>/dev/null
