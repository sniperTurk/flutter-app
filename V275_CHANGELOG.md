# V275

- Hardened App Store source preflight so `pubspec.yaml`, `pubspec.lock`, and `lockfile-provenance.txt` cannot be accepted through symbolic links.
- Added regression coverage for all three release trust inputs.
- Verified dependency-free Dart lint: 58 files, 0 issues.
- Verified Python suite: 314/314 tests pass.
- App Store preflight remains correctly BLOCKED because the real resolver-generated `pubspec.lock`, privacy-policy URL, and iOS scaffold are not present.
- No Flutter/iOS/Simulator/device success is claimed; Flutter SDK/macOS execution is unavailable in this environment.
