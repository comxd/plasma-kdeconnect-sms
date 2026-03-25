# Changelog

All notable changes to KDE Connect SMS will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/).

## [2.3.0] — 2026-03-25

### Changed

- Unread SMS badge replaced with dot indicator (count was unreliable due to upstream KDE Connect daemon cache bug)
- Plugin check uses native `PluginChecker` (signal-driven) instead of manual polling timer
- SMS app launch and conversation sync use native `SmsDbusInterfaceFactory` instead of shell commands
- Sync button now refreshes both contacts and SMS conversations
- Plugin check shows a loading spinner instead of a false error during async D-Bus resolution

### Fixed

- Stale plugin state on device switch (sync deferred until plugin availability confirmed)
- Timer `start()` replaced with `restart()` for correct behavior on overlapping events
- Contact autocomplete deduplication for multi-source KPeople contacts (Google, local, NextCloud)
- Phone type labels (Mobile, Work, Home, Fax) in contact autocomplete via PersonData vCard access
- Defensive signal handlers (dataChanged, layoutChanged) in contact dedup to prevent stale filter state
- Refresh button now shows spinning icon with minimum 2.5s visual feedback
- Send SMS button shows inline loading indicator during send
- Replaced standalone toolbar spinner with per-button inline feedback

### Docs

- FAQ updated for dot indicator
- 15 translations updated

## [2.2.0] — 2026-03-19

### Added

- About tab in popup with author info and links
- FAQ help tab in settings with collapsible Q&A for troubleshooting
- Unread count badge on conversation icon
- "About" entry in widget context menu
- Full-page SMS history view with back navigation (replaces inline collapsible section)
- Custom icon for General settings tab

### Changed

- Message field now clears immediately after successful send

### Removed

- Inline SMS reply from notifications (redundant with KDE native notification replies)
- Drag & drop file sharing (redundant with KDE Connect's Dolphin integration)

### Fixed

- Country override no longer resets when closing and reopening the popup
- FAQ titles vertically centered between separators
- QML cache invalidation on VM plasmoid install

## [2.1.1] — 2026-03-14

### Added

- Hide widget from panel option (show/hide via widget settings)

### Fixed

- Touch QML files at build time to invalidate Plasma cache on update

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
- Unread notification badge on panel icon
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

[2.3.0]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.3.0
[2.2.0]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.2.0
[2.1.1]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.1.1
[2.1.0]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.1.0
[2.0.0]: https://github.com/comxd/plasma-kdeconnect-sms/releases/tag/v2.0.0
