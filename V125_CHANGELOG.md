# V125 — Reproducible release preflight hardening

## Production change
- App Store source preflight now fails closed when `pubspec.lock` is missing or empty.
- The preflight also verifies that `.fvmrc` exists and pins Flutter `3.47.2`, matching the iOS scaffold bootstrap contract.
- No lockfile was fabricated. The current project intentionally remains BLOCKED until `flutter pub get` is run with the pinned Flutter SDK and its generated `pubspec.lock` is committed.

## Regression coverage
- Added tests for missing/empty `pubspec.lock`.
- Added tests for missing or mismatched `.fvmrc` Flutter pin.

## Verification boundary
- Python/offline checks can be run in this environment.
- Flutter/Dart/Xcode are not available here, so `flutter pub get`, `flutter analyze`, `flutter test`, iOS build, Simulator, device, signing and archive are not claimed as passed.
