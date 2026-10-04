# SNIPER TÜRK V1 — v172

## Production change

- Moved the committed `pubspec.lock` release gate ahead of Flutter SDK setup in iOS CI.
- CI now fails fast on the known reproducibility blocker instead of downloading/configuring Flutter first.
- The gate remains fail-closed and does not generate or mutate a lockfile; the lockfile must still come from pinned Flutter 3.47.2.
- Added regression coverage that locks the gate ordering and prevents duplicate/softened wiring.

## Verification in this environment

- Python compileall: PASS
- Offline Python regression suite: 103/103 PASS
- G1/G7 production gate: CLOSED/PASS
- Offline Dart source hygiene: PASS (53 Dart files, 0 lexical problems)
- Workflow ordering regression: PASS
- Real Flutter/Xcode/Simulator/device execution: NOT RUN (toolchain unavailable here)

## Remaining release blockers

- `pubspec.lock` still must be generated with the pinned Flutter 3.47.2 resolver and committed.
- Generated iOS scaffold and the real macOS/iOS CI gates still require Flutter/Xcode.
- A real public privacy-policy URL must be configured for App Store preflight.
- Signing, physical-device validation, TestFlight/App Store Connect upload and review remain owner/Apple-environment gates.
