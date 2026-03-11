#!/bin/bash
# Restart plasmashell preserving its original session environment
# This avoids losing icons/theme when restarting via serial console
#
# Usage:
#   bash restart-plasmashell.sh prepare  # Save current env (call BEFORE updating plasmoid)
#   bash restart-plasmashell.sh restart  # Kill + restart with saved env

set -euo pipefail

ENV_SCRIPT="/tmp/plasma-restart-env.sh"

case "${1:-}" in
    prepare)
        PID=$(pgrep -u neon plasmashell | head -1)
        if [ -z "$PID" ]; then
            echo "ERROR: No running plasmashell found"
            exit 1
        fi
        # Dump full env as safely escaped export statements
        while IFS= read -r -d '' line; do
            key="${line%%=*}"
            val="${line#*=}"
            printf 'export %s=%q\n' "$key" "$val"
        done < "/proc/$PID/environ" > "$ENV_SCRIPT"
        echo "  OK: plasmashell env saved (PID $PID)"
        ;;
    restart)
        if [ ! -f "$ENV_SCRIPT" ]; then
            echo "ERROR: No saved env. Run 'prepare' first."
            exit 1
        fi
        # Kill current plasmashell
        pkill -u neon plasmashell 2>/dev/null || true
        sleep 2
        # Restart with original env as neon user
        su - neon -c "source $ENV_SCRIPT; plasmashell &>/dev/null &"
        echo "  OK: plasmashell restarted with original env"
        ;;
    *)
        echo "Usage: $0 {prepare|restart}"
        exit 1
        ;;
esac
