#!/bin/bash
# Shared QEMU monitor sendkey helpers for host scripts
#
# Usage:
#   source "$(dirname "$0")/lib/sendkey.sh"
#
# Requires:
#   MONITOR_SOCK — must be set before sourcing
#
# Provides:
#   send_key()    — send a single key combo via QEMU monitor
#   send_string() — type a string character-by-character via sendkey

if [ -z "${MONITOR_SOCK:-}" ]; then
    echo "ERROR: MONITOR_SOCK must be set before sourcing sendkey.sh"
    exit 1
fi

send_key() {
    echo "sendkey $1" | socat - UNIX:"$MONITOR_SOCK" >/dev/null 2>&1
    sleep 0.05
}

send_string() {
    local str="$1"
    for (( i=0; i<${#str}; i++ )); do
        local c="${str:$i:1}"
        case "$c" in
            [a-z])  send_key "$c" ;;
            [A-Z])  send_key "shift-$(echo "$c" | tr '[:upper:]' '[:lower:]')" ;;
            [0-9])  send_key "$c" ;;
            ' ')    send_key "spc" ;;
            '/')    send_key "slash" ;;
            '\\')   send_key "backslash" ;;
            '-')    send_key "minus" ;;
            '=')    send_key "equal" ;;
            '.')    send_key "dot" ;;
            ',')    send_key "comma" ;;
            ';')    send_key "semicolon" ;;
            ':')    send_key "shift-semicolon" ;;
            "'")    send_key "apostrophe" ;;
            '"')    send_key "shift-apostrophe" ;;
            '&')    send_key "shift-7" ;;
            '|')    send_key "shift-backslash" ;;
            '_')    send_key "shift-minus" ;;
            '>')    send_key "shift-dot" ;;
            '<')    send_key "shift-comma" ;;
            '(')    send_key "shift-9" ;;
            ')')    send_key "shift-0" ;;
            $'\n')  send_key "ret" ;;
            *)      echo "WARN: unknown char '$c'" ;;
        esac
    done
}
