# V129 — async Home profile-load race hardening

- Added a monotonically increasing `_loadGeneration` to `HomeScreen._load()`.
- Stale asynchronous profile loads now exit before active-profile reconciliation or UI state mutation, preventing an older read from overwriting a newer refresh/navigation return.
- Added an offline structural regression test that verifies the stale-result guard remains before persistence reconciliation.
- Added the new regression test to iOS CI Python validation.
- No Flutter/iOS build success is claimed in this environment; Flutter/Dart/Xcode execution remains externally required.
