# V182 — independent-audit fixes for v181

No app/catalog/ballistics code changed. Findings come from an independent
audit of v181 (numbering below matches that report).

## Fixed
- **#5 (LOW)** `verify_ios_privacy_manifests.py` only caught
  `plistlib.InvalidFileException`; a truncated XML plist raised an uncaught
  `ExpatError` (still exit 1, but with a traceback and no clean message). Any
  parse failure is now reported as `invalid privacy manifest(s): <path> (<ErrorType>)`.
- **#4 (MEDIUM)** `["CA92.1", "JUNK"]` passed the gate. Every declared reason must
  now be a string shaped like an Apple reason code (`^[0-9A-Z]{4}\.[0-9]$`);
  malformed entries/lists/keys also fail. Well-formed codes for other
  categories or other UserDefaults reasons (e.g. `1C8F.1`, `C617.1`) are
  deliberately NOT rejected, to avoid false failures on legitimate plugin
  manifests. The gate still requires at least one recognized pair (UserDefaults/CA92.1).
- **#3 (MEDIUM)** The gate accepted an archive whose only manifest came from a
  plugin framework. It now prints a WARNING when `Runner.app/PrivacyInfo.xcprivacy`
  is absent and supports `--require-runner-manifest` to make it an error.
  It is NOT enabled in CI: nothing in this repo creates an app manifest and
  whether the pinned Flutter 3.47.2 scaffold ships one is unverified, so
  hard-requiring it could make CI unsatisfiable. Enable it once the app ships one.
- 9 new tests (truncated XML, junk-beside-valid, other valid codes accepted,
  malformed structures, wrong category, valid+corrupt pair, warning/required
  flag, CLI exit codes with no traceback).

## Not fixed, tooling only
- **#1 (HIGH)** the `dart format --set-exit-if-changed` gate will very likely
  fail (45 of 53 Dart files contain unformatted patterns: 690 lines > 80 cols,
  994 unspaced named arguments). Only the SDK formatter can fix this; it cannot
  be done offline. Added `tools/format_dart.sh` (+ contract test, CLAUDE.md note):
  run it once with pinned Flutter/Dart, commit the diff.
- **#2** `pubspec.lock`, generated `ios/` and `PRIVACY_POLICY_URL` remain owner /
  macOS-environment items by design.

## Verification (executed here)
See delivery message. Flutter/Dart/Xcode/Simulator/archive were NOT run.
