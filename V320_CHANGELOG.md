# V320_CHANGELOG

- App Store source preflight now rejects symbolic-link directories anywhere under `lib/` or `integration_test/` capability-scan trees.
- This closes a fail-open path where a symlinked directory could hide camera/location/microphone/photo-library Dart usage from the static capability scan and bypass required Info.plist purpose-string enforcement.
- Added a red/green regression test proving v319 accepted the symlink-directory fixture and v320 rejects it.
- Validation: 412/412 Python tests; offline Dart lint 59/59; Python compileall; shell syntax.
- Flutter/Xcode/Simulator/physical-device execution remains unverified in this environment.
