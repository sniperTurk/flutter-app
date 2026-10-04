# V124 — 2026-09-26

## P0 compile blocker removed from ProfileCodec

- Removed the unscoped `.firstOrNull` use from `lib/services/profile_codec.dart`.
- No new dependency was added; decode now uses standard Dart `Iterable.isEmpty` / `Iterable.first`.
- Existing forward-compatible behavior is preserved: unknown or missing `angularUnit` falls back to `AngularUnit.mrad`.
- Audited every remaining `.firstOrNull` use in `lib/`: Home and Profiles are covered by their file-local `_FirstOrNull` extensions.

## Verification in this environment

- Python/offline checks: run separately for this build.
- Flutter/Dart analyze/tests: NOT RUN (Flutter/Dart SDK unavailable in this runtime).
- iOS build/Simulator/device: NOT RUN (Xcode/macOS unavailable in this runtime).
