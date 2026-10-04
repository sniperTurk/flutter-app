# V137 changelog

## Deterministic iOS export-compliance metadata

- Added `ITSAppUsesNonExemptEncryption = false` to the deterministic iOS `Info.plist` configuration applied after Flutter scaffold generation.
- App Store source preflight now fails closed when that export-compliance declaration is missing or is not explicitly `false`.
- Added regression coverage for the metadata writer and release preflight contract.
- Offline Python regression suite is 38/38 PASS in this environment.
- Real Flutter analysis/tests and iOS build/Simulator/device execution remain unverified here because Flutter/Dart/Xcode are unavailable.
