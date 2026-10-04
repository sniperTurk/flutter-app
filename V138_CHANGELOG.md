# SNIPER TÜRK V1 — v138

## Production work completed

- Added a distinct unsigned App Store archive gate to `.github/workflows/ios-ci.yml` after the unsigned device build.
- CI now runs `flutter build ipa --release --no-codesign`, requires the generated `Runner.xcarchive/Info.plist`, and verifies the archive bundle identifier is exactly `com.sniperturk.sniperTurk`.
- The archive remains deliberately unsigned: distribution signing/export still requires the owner's Apple credentials and is not claimed as completed.
- Added `tools/test_ios_ci_archive_wiring.py` so removal/reordering of the archive gate is caught by the offline regression suite.

## Verification in this environment

- Offline Python regression suite: 39/39 PASS.
- Python compile for the new guard: PASS.
- `bootstrap_ios_scaffold.sh` syntax: PASS.
- G1/G7 production gate: CLOSED/PASS.
- Real Flutter/Dart/Xcode execution: NOT AVAILABLE in this environment; archive creation itself is therefore not claimed as successful.
