#!/bin/bash
# Wrapper: run setup-vm.sh with logging and completion marker
# Designed to be backgrounded by launch-vm.sh via serial console:
#   vm_serial "bash /mnt/plasmoid/vm/guest/run-setup-bg.sh &"
#
# Output → /tmp/setup-vm.log
# Completion marker → /tmp/setup-vm.done (contains "OK" or "FAIL:<exit_code>")

LOG="/tmp/setup-vm.log"
DONE="/tmp/setup-vm.done"

rm -f "$LOG" "$DONE"

if bash /mnt/plasmoid/vm/guest/setup-vm.sh > "$LOG" 2>&1; then
    echo "OK" > "$DONE"
else
    echo "FAIL:$?" > "$DONE"
fi
