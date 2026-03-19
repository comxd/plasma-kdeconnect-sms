#!/bin/bash
# Start a shell listener on the serial port (/dev/ttyS0)
# This allows the host to send commands to the VM via the serial socket.
#
# Called by: launch-vm.sh --setup (via sendkey bootstrap)
# The host sends commands via: (echo "cmd"; sleep 2) | socat -t3 - UNIX:/tmp/<VM_NAME>-vm-serial.sock

set -uo pipefail

SERIAL_DEV="/dev/ttyS0"
LOCKFILE="/tmp/serial-shell.lock"

if [ ! -e "$SERIAL_DEV" ]; then
    echo "ERROR: Serial device $SERIAL_DEV not found"
    exit 1
fi

# Prevent multiple instances competing for the same serial port
exec 200>"$LOCKFILE"
flock -n 200 || { echo "Serial shell already running"; exit 0; }

echo "Serial shell started on $SERIAL_DEV (PID $$)"

# Read commands from serial port, execute them, send output back
# Uses bash -c (not eval) to avoid double-expansion of shell metacharacters
while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    bash -c "$cmd" 2>&1
done < "$SERIAL_DEV" > "$SERIAL_DEV"
