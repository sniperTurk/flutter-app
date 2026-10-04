# SNIPER TÜRK V1 — v141

## Production work completed

- Removed stale hard-coded App Store archive version/build expectations from iOS CI.
- The archive gate now derives `CFBundleShortVersionString` and `CFBundleVersion` expectations directly from the `version:` in `pubspec.yaml`, which is the same release identity consumed by Flutter.
- Added fail-closed validation for malformed `pubspec.yaml` release versions before archive metadata comparison.
- Strengthened the archive metadata regression test so hard-coded `1.0.0` / `1` expectations cannot silently return.

## Verification in this environment

- Offline Python regression suite: executed locally; result recorded from the actual run.
- Python compile for verification tools: executed locally.
- GitHub Actions YAML parse: executed locally with available YAML parser.
- `bootstrap_ios_scaffold.sh` syntax: executed locally.
- G1/G7 production gate: executed locally.
- Real Flutter/Dart/Xcode execution: NOT AVAILABLE in this environment and is not claimed as successful.
