#!/bin/bash
# Launch KDE Neon VM for testing the KDE Connect SMS plasmoid
#
# Usage:
#   ./vm/launch-vm.sh             # Boot live session (manual setup)
#   ./vm/launch-vm.sh --setup     # Boot + wait + auto-setup (fully automated)
#   ./vm/launch-vm.sh --serial    # Wait for serial shell, then connect
#
# With --setup:
#   1. Starts QEMU in background
#   2. Confirms GRUB default entry (sendkey Enter after ~8s)
#   3. Bootstraps serial shell with retry (up to 5 attempts, ~20s apart)
#   4. Runs full setup (install plasmoid, add to panel)
#
# Without --setup (manual):
#   1. Boot the VM, wait for desktop
#   2. Bootstrap serial shell manually in the VM
#   3. Reload: ./vm/reload-plasmoid.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

export VM_NAME="${VM_NAME:-$(sed -n 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PROJECT_DIR/metadata.json" 2>/dev/null)}"
if [ -z "$VM_NAME" ]; then
    echo "ERROR: Could not determine VM_NAME — no \"Id\" field in metadata.json"
    exit 1
fi

ISO="${KDE_NEON_ISO:-}"
DISK="/tmp/${VM_NAME}-vm.qcow2"
OVMF_VARS="/tmp/${VM_NAME}-vm-OVMF_VARS.fd"
MONITOR_SOCK="/tmp/${VM_NAME}-vm-monitor.sock"
SERIAL_SOCK="/tmp/${VM_NAME}-vm-serial.sock"
RAM="4G"
CPUS="4"
VM_WIDTH="${VM_WIDTH:-1920}"
VM_HEIGHT="${VM_HEIGHT:-1080}"
VM_SCALE="${VM_SCALE:-auto}"

# ── Create disk image if needed ──
if [ ! -f "$DISK" ]; then
    echo "Creating VM disk image (40GB, thin-provisioned)..."
    qemu-img create -f qcow2 "$DISK" 40G
fi

# ── Create writable OVMF VARS if needed ──
if [ ! -f "$OVMF_VARS" ]; then
    echo "Creating UEFI VARS copy..."
    cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OVMF_VARS"
fi

# ── Serial mode: wait for serial shell and connect ──
if [ "${1:-}" = "--serial" ]; then
    echo "Waiting for serial shell on $SERIAL_SOCK..."
    echo "(Use --setup mode or bootstrap serial shell manually)"
    for i in $(seq 1 60); do
        if [ -S "$SERIAL_SOCK" ]; then
            echo "Connecting to serial console..."
            exec socat -,rawer UNIX:"$SERIAL_SOCK"
        fi
        printf "."
        sleep 2
    done
    echo ""
    echo "ERROR: Serial socket not found after 2 minutes."
    exit 1
fi

# ── Check ISO ──
if [ -z "$ISO" ]; then
    echo "ERROR: KDE_NEON_ISO not set."
    echo "  export KDE_NEON_ISO=/path/to/neon-user-current.iso"
    echo "  Download: https://files.kde.org/neon/images/user/current/neon-user-current.iso"
    exit 1
fi
if [ ! -f "$ISO" ]; then
    echo "ERROR: ISO not found at $ISO"
    echo "  Download: https://files.kde.org/neon/images/user/current/neon-user-current.iso"
    exit 1
fi

# ── QEMU command (as an array, reused by both modes) ──
QEMU_CMD=(
    qemu-system-x86_64
    -name "KDE Neon - KDE Connect SMS Dev"
    -machine q35,accel=kvm
    -cpu host
    -smp "$CPUS"
    -m "$RAM"

    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
    -drive "if=pflash,format=raw,file=$OVMF_VARS"

    -drive "file=$DISK,format=qcow2,if=virtio"

    -netdev user,id=net0
    -device virtio-net-pci,netdev=net0

    -device "virtio-vga-gl,xres=$VM_WIDTH,yres=$VM_HEIGHT"
    -display gtk,gl=on,zoom-to-fit=on

    -device qemu-xhci
    -device usb-tablet

    -chardev qemu-vdagent,id=vdagent,name=vdagent,clipboard=on
    -device virtio-serial
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0

    -serial "unix:$SERIAL_SOCK,server=on,wait=off"
    -monitor "unix:$MONITOR_SOCK,server=on,wait=off"

    -audiodev pipewire,id=audio0
    -device ich9-intel-hda
    -device hda-duplex,audiodev=audio0

    -virtfs "local,path=$PROJECT_DIR,mount_tag=plasmoid,security_model=mapped-xattr,id=plasmoid_share"

    -device ahci,id=ahci
    -device ide-cd,drive=cd0,bus=ahci.0
    -drive "id=cd0,if=none,format=raw,file=$ISO,readonly=on"
    -boot d
)

# ── Setup mode: fully automated boot + setup ──
if [ "${1:-}" = "--setup" ]; then

    if ! command -v socat &>/dev/null; then
        echo "ERROR: socat is required. Install it: sudo apt install socat"
        exit 1
    fi

    source "$SCRIPT_DIR/lib/sendkey.sh"
    source "$SCRIPT_DIR/lib/serial.sh"

    echo "=== KDE Connect SMS — Automated VM Setup ==="
    echo ""
    echo "Starting QEMU in background..."

    "${QEMU_CMD[@]}" &
    QEMU_PID=$!
    trap 'kill $QEMU_PID 2>/dev/null; exit' INT TERM

    # Wait for monitor socket to appear
    echo "Waiting for QEMU monitor socket..."
    for i in $(seq 1 20); do
        if [ -S "$MONITOR_SOCK" ]; then
            echo "  OK: monitor socket ready"
            break
        fi
        if [ "$i" -eq 20 ]; then
            echo "ERROR: Monitor socket not found after 10 seconds."
            kill $QEMU_PID 2>/dev/null
            exit 1
        fi
        sleep 0.5
    done

    # ── Boot GRUB default entry ──
    # KDE Neon live ISO GRUB does NOT auto-boot — must press Enter to confirm
    # Wait for OVMF firmware to complete (~8s), then send Enter to boot GRUB
    echo ""
    echo "Waiting for GRUB menu..."
    sleep 8
    send_key "ret"
    echo "  OK: GRUB boot confirmed"

    # ── Bootstrap serial shell (retry loop) ──
    # Try up to 5 times: sendkey bootstrap → test serial, wait 20s between attempts
    # Desktop may not be ready on first attempts — keys are harmlessly lost
    BOOTSTRAP='sudo mkdir -p /mnt/plasmoid && sudo mount -t 9p -o trans=virtio,access=any plasmoid /mnt/plasmoid 2>/dev/null; sudo bash /mnt/plasmoid/vm/guest/serial-shell.sh &'
    SERIAL_OK=""

    echo ""
    echo "Waiting for desktop and bootstrapping serial shell..."
    sleep 20  # minimum wait for kernel boot

    for attempt in $(seq 1 5); do
        echo ""
        echo "  Attempt $attempt/5: sending bootstrap keys..."

        # Open Konsole via KRunner and type bootstrap command
        send_key "alt-f2"
        sleep 2
        send_string "konsole"
        sleep 1
        send_key "ret"
        sleep 3
        send_string "$BOOTSTRAP"
        send_key "ret"
        sleep 4

        # Quick serial test (5 tries × 2s = 10s)
        for _ in $(seq 1 5); do
            RESULT=$( (echo "echo SERIAL_OK"; sleep 2) | socat -t3 - UNIX:"$SERIAL_SOCK" 2>/dev/null || true)
            if echo "$RESULT" | grep -q "SERIAL_OK"; then
                SERIAL_OK="yes"
                echo "  OK: Serial shell connected!"
                break 2
            fi
            sleep 2
        done

        if [ "$attempt" -lt 5 ]; then
            echo "  Desktop not ready, retrying in 15s..."
            sleep 15
        fi
    done

    if [ -z "$SERIAL_OK" ]; then
        echo ""
        echo "  ERROR: Serial shell not responding after 5 attempts."
        echo "  Keeping VM alive (Ctrl+C to stop)..."
        wait $QEMU_PID
        exit 1
    fi

    # ── Run full setup via serial console ──
    # Background the setup in the guest so the serial shell stays free for polling.
    # Output goes to /tmp/setup-vm.log, completion marker to /tmp/setup-vm.done.
    echo ""
    echo "Running setup via serial console (backgrounded)..."
    vm_serial "bash /mnt/plasmoid/vm/guest/run-setup-bg.sh &"
    sleep 2

    # Poll for completion marker (setup typically takes 30-60s)
    echo "Waiting for setup to complete..."
    SETUP_OK=""
    for i in $(seq 1 40); do
        sleep 5
        RESULT=$(vm_serial "cat /tmp/setup-vm.done 2>/dev/null" 1 2 || true)
        if echo "$RESULT" | grep -q "^OK"; then
            SETUP_OK="yes"
            break
        fi
        if echo "$RESULT" | grep -q "^FAIL"; then
            echo ""
            echo "ERROR: Setup failed! Log:"
            vm_serial "cat /tmp/setup-vm.log" 1 5
            echo ""
            echo "Keeping VM alive for debugging (Ctrl+C to stop)..."
            wait $QEMU_PID
            exit 1
        fi
        printf "."
    done

    if [ -z "$SETUP_OK" ]; then
        echo ""
        echo "ERROR: Setup timed out after ~200 seconds."
        echo "Partial log:"
        vm_serial "cat /tmp/setup-vm.log" 1 5
        echo ""
        echo "Keeping VM alive for debugging (Ctrl+C to stop)..."
        wait $QEMU_PID
        exit 1
    fi

    echo ""
    echo "Setup log:"
    vm_serial "cat /tmp/setup-vm.log" 1 5

    # ── Configure HiDPI scaling if needed ──
    SCALE="$VM_SCALE"
    if [ "$SCALE" = "auto" ]; then
        if [ "$VM_WIDTH" -ge 3840 ]; then
            SCALE=2
        else
            SCALE=1
        fi
    fi
    if [ "$SCALE" != "1" ]; then
        echo ""
        echo "Configuring HiDPI scaling (${SCALE}x)..."
        vm_serial "su - neon -c 'DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 kscreen-doctor output.1.scale.$SCALE'" 2 3
        echo "  OK: Scale set to ${SCALE}x (resolution: ${VM_WIDTH}x${VM_HEIGHT})"
    fi

    echo ""
    echo "=== Fully automated setup complete! ==="
    echo "  - Click the widget icon in the panel to see the popup"
    echo "  - Reload after code changes: ./vm/reload-plasmoid.sh"
    echo "  - Interactive serial shell:  socat -,rawer UNIX:$SERIAL_SOCK"
    echo ""
    echo "VM is running (PID $QEMU_PID). Press Ctrl+C to stop."

    wait $QEMU_PID
    exit 0
fi

# ── Normal mode: just launch QEMU ──

echo "Booting KDE Neon live session..."
echo "  Serial console: socat -,rawer UNIX:$SERIAL_SOCK"
echo "  QEMU monitor:   socat - UNIX:$MONITOR_SOCK"
echo "  Shared folder:   $PROJECT_DIR → /mnt/plasmoid (9p virtio)"
echo ""
echo "  After desktop loads:"
echo "    1. Setup:  ./vm/launch-vm.sh --setup (recommended)"
echo "    2. Reload: ./vm/reload-plasmoid.sh"
echo ""
echo "  Or use fully automated mode: ./vm/launch-vm.sh --setup"
echo ""

exec "${QEMU_CMD[@]}"
