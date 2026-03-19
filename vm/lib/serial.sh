#!/bin/bash
# Shared serial console helpers for host scripts
#
# Usage:
#   source "$(dirname "$0")/lib/serial.sh"
#
# Provides:
#   SERIAL_SOCK — path to the serial Unix socket
#   vm_serial() — send a command to the VM via serial console
#   check_serial_sock() — exit with error if socket is missing

# VM_NAME should be set by the calling script (launch-vm.sh or reload-plasmoid.sh)
VM_NAME="${VM_NAME:-plasmoid}"
SERIAL_SOCK="/tmp/${VM_NAME}-vm-serial.sock"

vm_serial() {
    # Send a command and read output. Optional: vm_serial "cmd" [input_wait] [read_timeout]
    #   input_wait:   seconds to keep stdin open after sending (default: 2)
    #   read_timeout: socat -t value, seconds to wait for data after stdin closes (default: 3)
    local input_wait="${2:-2}"
    local read_timeout="${3:-3}"
    (echo "$1"; sleep "$input_wait") | socat -t"$read_timeout" - UNIX:"$SERIAL_SOCK" 2>/dev/null
}

check_serial_sock() {
    if [ ! -S "$SERIAL_SOCK" ]; then
        echo "ERROR: Serial socket not found at $SERIAL_SOCK"
        echo "  Is the VM running?  → ./vm/launch-vm.sh"
        echo "  Setup done?         → ./vm/launch-vm.sh --setup"
        exit 1
    fi
}
