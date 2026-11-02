# Changelog

All notable changes to PocketFin are documented here.

## [1.0.0] - 2026-11-02

First stable release.

### Added

- Offline-first transaction tracking with a local SQLite database (Drift).
- Home dashboard with balance, monthly budget and today's entries.
- Custom new-entry flow with expense/income toggle, categories and a numeric
  keypad.
- Stats screen with week/month/year periods, category donut, daily spend chart
  and a comparison tip.
- Coach screen with insights generated from the user's own history.
- Excel export (`.xlsx`) with the native share sheet.
- Excel import (`.xlsx`) that merges with existing data and skips duplicate
  entries.
- Demo data mode for previewing the UI (`--dart-define=SEED_DEMO=true`).
- Dark theme, custom typography, launcher icon and splash screen.
- Unit and widget tests for analytics, persistence, import/export and the main
  flows.

### Known limitations

- Legacy `.xls` export is not implemented; use `.xlsx`.
- The Android release APK is signed with Flutter's debug key.
- iOS has not been compiled in CI.

[1.0.0]: https://github.com/LyeZinho/pocketfin/releases/tag/v1.0.0
