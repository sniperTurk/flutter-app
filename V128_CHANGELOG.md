# SNIPER TÜRK V1 — v128

## Production change
- App Store source preflight now validates the iOS application identity in `Runner.xcodeproj/project.pbxproj` instead of trusting that the scaffold was generated correctly in the past.
- The Runner bundle identifier must be exactly `com.sniperturk.sniperTurk`.
- The generated test target identifier `com.sniperturk.sniperTurk.RunnerTests` is explicitly allowed; unrelated/stale bundle identifiers fail closed.
- Added regression coverage for wrong Runner bundle IDs and the valid RunnerTests companion ID.

## Verification performed in this environment
- Offline Python verification suite executed after the change.
- Python source compilation, Bash syntax, workflow YAML parsing, production gate and archive integrity are checked before packaging.
- Real App Store preflight remains intentionally blocked until the resolver-generated `pubspec.lock`, a real privacy-policy URL, and generated iOS scaffold exist.

## Not verified here
Flutter/Dart/Xcode are not available in this environment. `flutter pub get`, `flutter analyze`, `flutter test`, iOS build, Simulator launch, physical-device testing, signing/archive and App Store upload are not claimed as successful.
