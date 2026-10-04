# SNIPER TÜRK V1 — v127

## Production change
- iOS scaffold bootstrap now deterministically configures the user-facing `CFBundleDisplayName` as `SNIPER TÜRK` instead of leaving Flutter's generated project/package name visible to users.
- Added `tools/configure_ios_info_plist.py` so the metadata mutation is isolated, deterministic and unit-testable.
- App Store preflight now fails closed when an existing iOS `Info.plist` is invalid or its display name is not exactly `SNIPER TÜRK`.
- iOS CI compiles and tests the new metadata helper.

## Verification performed in this environment
- Offline Python verification suite: 24/24 PASS.
- Python `py_compile`: PASS.
- `bootstrap_ios_scaffold.sh` Bash syntax: PASS.
- GitHub Actions workflow YAML parse: PASS.
- G1/G7 production gate contract: CLOSED / PASS.
- Real App Store preflight remains BLOCKED because `pubspec.lock`, privacy-policy URL and generated `ios/` scaffold are not present.

## Not verified here
Flutter/Dart/Xcode are not available in this environment. `flutter pub get`, `flutter analyze`, `flutter test`, iOS build, Simulator launch, physical-device testing, signing/archive and App Store upload are not claimed as successful.
