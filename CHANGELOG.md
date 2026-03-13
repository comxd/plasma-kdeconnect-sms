# Changelog

All notable changes to KDE Connect SMS will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/).

## [2.1.0] — 2026-03-13

### Added

- Inline country picker using StackLayout pattern (replaces popup overlay)
- Auto-focus phone field on popup open

### Fixed

- Country picker now usable in taskbar panel mode
- Country selection in settings is now properly saved and restored
- Popup content no longer overflows rounded background
- Spacing below message textarea

### Changed

- Popup layout uses PlasmaExtras.Representation for proper clipping and margins
- Contact chip redesigned as compact pill with subtle border
- VM reload script supports `--reset` flag to clear widget settings

## [2.0.0] — 2026-03-11

Complete rewrite for KDE Plasma 6 (Qt 6 / QML).

### Added

- Compose and send SMS from your desktop via KDE Connect
- Contact autocomplete powered by KPeople with photo support
- As-you-type phone number formatting with automatic country detection (libphonenumber-js)
- SMS history per contact with collapsible section and smooth animations
- Inline SMS reply directly from KDE Connect notifications
- Drag & drop file sharing to your phone via KDE Connect
- Autoconfiguration when only one device is paired
- Press Enter in phone field to jump to message field
- Auto-clear message field after sending
- Confirmation message after SMS sent
- Configurable speaker beep on send
- KDE Connect device selection in settings
- Custom SVG icons (panel icon + store logo) with KDE color scheme support
- 15 language translations (fr, de, es, pt_BR, ru, zh_CN, ja, ko, it, nl, pl, tr, ar, uk, cs)

### Changed

- Complete rewrite from Plasma 5 to Plasma 6
- Native KDE Connect QML API instead of shell commands

[2.1.0]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.1.0
[2.0.0]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.0.0
