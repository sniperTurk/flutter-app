# V274 — retired-feature production surface guard

Continues V273 without restarting the project.

## Production hardening
Added a repository-wide regression contract that prevents the four retired V1 tools (Chronograph, Sight Height camera/measurement tool, Compass, Bubble Level) from silently returning through source files, home navigation labels/routes, or sensor/camera/audio package dependencies.

The guard deliberately preserves `sightHeightMm` as a manual ballistic input: removing the retired Sight Height measurement feature must not corrupt the trajectory/profile model.

## Verification
- complete offline Python suite: 313/313 passed
- Python compileall: passed
- offline Dart source lint: passed
- G1/G7 production gate remains CLOSED
- App Store preflight remains BLOCKED because `pubspec.lock`, privacy-policy URL, and generated iOS scaffold are not available in this environment
- no real Flutter/iOS build, Simulator, or physical-device result was produced
