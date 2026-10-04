# SNIPER TÜRK V1 — v168

## Production change

- Continued from the verified v167 source tree; no project restart.
- Expanded the real optics catalog with two current manufacturer-backed Vector Optics long-range FFP/MIL models:
  - Continental x6 5–30×56 VCT FFP PRS (SCFF-30)
  - Tauron 5–30×56 GenII FFP (SCFF-66)
- Stored only values published on the live manufacturer pages; no BC, dimensions, ranges, or optical properties were inferred.
- Added `tools/test_v168_vector_long_range_expansion.py` to lock the new records, provenance markers, and global scope-ID uniqueness.

## Verification in this environment

- Python tool compile: PASS.
- Complete offline Python unittest discovery: PASS (92 tests).
- Offline Dart lexical lint: PASS (53 Dart files, 0 issues).
- Production G1/G7 gate: CLOSED/PASS.
- Flutter/Dart SDK is not installed in this runtime, so `flutter analyze`, `flutter test`, iOS build, Simulator launch, and physical-device testing were NOT run and are NOT claimed as passing.
- App Store preflight remains blocked by the pre-existing missing `pubspec.lock`, privacy-policy URL configuration, and generated iOS scaffold; these require the pinned Flutter/macOS release environment and owner configuration.
