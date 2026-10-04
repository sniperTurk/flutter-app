# V183 — fail-closed Runner privacy-manifest CI gate

## Changed
- Closed the remaining v182 privacy-manifest fail-open wiring: the iOS CI archive gate now invokes `verify_ios_privacy_manifests.py` with `--require-runner-manifest`.
- A plugin/framework `PrivacyInfo.xcprivacy` can therefore no longer make CI green when the app's own top-level `Runner.app/PrivacyInfo.xcprivacy` is absent.
- Strengthened `test_ios_ci_privacy_manifest_wiring.py` so removal of the strict flag is a regression failure.

## Important consequence
- This is intentionally fail-closed. The repository still generates `ios/` on a pinned Flutter 3.47.2 host and no real Flutter/Xcode run was available here. If the generated/scaffolded Runner does not ship a top-level privacy manifest, the real macOS CI will now stop at this gate rather than report a false PASS. The next macOS production step must add/wire the app-owned manifest before App Store delivery.
- `dart format`, `flutter analyze`, `flutter test`, Xcode build, Simulator, xcarchive and physical-device validation were NOT run here.

## Verification executed
- Python unittest discovery: 155/155 PASS.
- Python compileall: PASS.
- offline Dart lint: PASS (53 Dart files, 0 lexical/structural problems).
- G1/G7 production gate: CLOSED/PASS.
- shell `bash -n`: PASS for project shell scripts.
- workflow YAML parse: PASS when PyYAML is available.
