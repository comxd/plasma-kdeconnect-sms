#!/bin/bash
# Quick-reload the plasmoid in the VM via serial console
#
# Usage:
#   ./vm/reload-plasmoid.sh              # Update plasmoid + restart plasmashell
#   ./vm/reload-plasmoid.sh --reinstall  # Remove + reinstall + restart + add to panel
#
# Prerequisites:
#   - VM running with serial console (launched via ./vm/launch-vm.sh)
#   - Serial shell started (via ./vm/launch-vm.sh --setup)

set -euo pipefail

source "$(dirname "$0")/lib/neon.sh"

PLUGIN_ID="com.comexpertise.plasma.kdeconnectsms"

check_serial_sock

# Save plasmashell env + create restart helper script in VM
# This preserves XDG_DATA_DIRS, icon theme, Qt platform, etc.
echo "Preparing plasmashell restart script..."
vm_serial 'bash /mnt/plasmoid/vm/guest/restart-plasmashell.sh prepare'

if [ "${1:-}" = "--reinstall" ]; then
    echo "Reinstalling plasmoid..."
    vm_as_neon "kpackagetool6 -t Plasma/Applet -r ${PLUGIN_ID} 2>/dev/null; kpackagetool6 -t Plasma/Applet -i /mnt/plasmoid"
    sleep 1

    echo "Restarting plasmashell (with original env)..."
    vm_serial 'bash /mnt/plasmoid/vm/guest/restart-plasmashell.sh restart'
    sleep 5

    echo "Adding widget to panel..."
    vm_serial "bash /mnt/plasmoid/vm/guest/add-to-panel.sh"
else
    echo "Updating plasmoid..."
    vm_as_neon "kpackagetool6 -t Plasma/Applet -u /mnt/plasmoid"
    sleep 1

    echo "Restarting plasmashell (with original env)..."
    vm_serial 'bash /mnt/plasmoid/vm/guest/restart-plasmashell.sh restart'
    sleep 5
fi

echo "Done — plasmashell restarted."
