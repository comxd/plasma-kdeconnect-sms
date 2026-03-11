#!/bin/bash
# Add the KDE Connect SMS widget to the first panel and the desktop
# Handles both neon user and root execution (serial shell runs as root)
#
# Usage: bash add-to-panel.sh
# Called by: setup-vm.sh (via serial console, runs as root)

set -euo pipefail

WIDGET_ID="com.comexpertise.plasma.kdeconnectsms"

# Helper to run a Plasma scripting JS snippet
run_plasma_script() {
    local script="$1"
    if [ "$(whoami)" = "root" ]; then
        su - neon -c "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000 qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '$script'"
    else
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"
    fi
}

# 1. Add to panel
PANEL_SCRIPT="var p=panels();if(p.length>0){p[0].addWidget(\"$WIDGET_ID\");}"
run_plasma_script "$PANEL_SCRIPT"

# 2. Add to desktop
DESKTOP_SCRIPT="var d=desktops();if(d.length>0){d[0].addWidget(\"$WIDGET_ID\");}"
run_plasma_script "$DESKTOP_SCRIPT"
