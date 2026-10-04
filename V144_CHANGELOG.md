# SNIPER TÜRK V1 — v144

## Production change
- Replaced the unsourced AEA Challenger Pro 6.35 catalog stub with a source-backed record.
- Added .25/6.35-specific magazine capacity (10), 610 mm barrel, 350 cc air tube, 840 mm overall length, 3.72 kg weight, and Picatinny/Weaver optic rail.
- Provenance is deliberately recorded as Airgun Armoury rather than AEA because the verified current source is a retailer listing, not an AEA manufacturer page.
- Added Dart catalog regression coverage and an offline Python provenance regression test wired into iOS CI.

## Verification performed in this environment
- Offline Python regression suite: 44/44 PASS.
- Python verification tools: py_compile PASS.
- GitHub Actions YAML parse: PASS.
- `tools/bootstrap_ios_scaffold.sh`: bash syntax PASS.
- G1/G7 production gate: CLOSED/PASS.
- App Store source preflight: BLOCKED as expected because `pubspec.lock`, a real HTTPS privacy-policy URL, and generated iOS scaffold are still absent.
- Flutter/Dart/Xcode execution was not available here; no real Flutter build, Simulator, device, or App Store upload is claimed.
