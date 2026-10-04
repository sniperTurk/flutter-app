# V126 CHANGELOG — CI dependency reproducibility gate

## Production change
- Closed a release-CI gap introduced by treating `flutter pub get` as both validation and generation: CI previously allowed a missing committed `pubspec.lock` to be generated during the run, hiding a reproducibility blocker already detected by the v125 App Store preflight.
- macOS iOS CI now fails before dependency resolution unless `pubspec.lock` exists and is non-empty.
- CI hashes the committed lockfile before and after `flutter pub get` under pinned Flutter 3.47.2 and fails if dependency resolution changes it. This prevents uncommitted resolver drift from being treated as a valid release build.
- `tools/app_store_preflight.py` and its regression tests are now part of the CI Python compile/unit-test stage so the release-source gate itself cannot silently rot.

## Verification in this environment
- Python offline verification suites pass, including the v125 App Store preflight regression tests.
- Workflow text was inspected for the new pre-resolution lockfile gate and post-resolution SHA-256 drift gate.
- The actual project intentionally still has no `pubspec.lock`; therefore a real CI run is expected to fail closed at the new gate until pinned Flutter 3.47.2 generates and commits the real lockfile.
- Flutter/Dart/Xcode are unavailable here. No `flutter pub get`, `flutter analyze`, `flutter test`, Xcode build, Simulator or device success is claimed.

## P0 CI parse blocker found and fixed during v126 verification
- Parsing the workflow with a real YAML parser exposed a pre-existing indentation defect in the inline Python heredoc used to select an iOS Simulator. The workflow was syntactically invalid YAML, so GitHub Actions could reject it before any Flutter job ran.
- Removed the fragile inline heredoc and added `tools/select_ios_simulator.py`, which selects an available iOS Simulator from `xcrun simctl ... -j` output and fails closed when the query fails or no device is available.
- Added regression tests for iOS-only selection, unavailable devices, and malformed entries; the CI Python compile/test stage now covers this helper.
- The repaired `.github/workflows/ios-ci.yml` is parsed with PyYAML in this environment as a structural verification step. This is workflow-syntax validation, not a claim that GitHub Actions, Xcode, Simulator or Flutter actually ran.
