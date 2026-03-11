# VM Testing

```bash
export KDE_NEON_ISO=/path/to/neon-user-current.iso

./vm/launch-vm.sh           # Start QEMU VM (manual mode)
./vm/launch-vm.sh --setup   # Fully automated: boot + install + setup
./vm/launch-vm.sh --serial  # Connect to serial console
./vm/reload-plasmoid.sh     # Reload after code changes
```

Requires: QEMU with KVM, socat, [KDE Neon ISO](https://files.kde.org/neon/images/user/current/neon-user-current.iso).
