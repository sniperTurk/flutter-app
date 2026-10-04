# V123 — 2026-09-26

## Catalog provenance is now visible in the production UI

- Ammunition rows now show caliber, grain weight, projectile type, and source provenance.
- Scope rows now show objective size, click value/unit, and source provenance.
- Unsourced/manual records are explicitly labelled `Kaynak doğrulanmadı` instead of looking equivalent to manufacturer-verified records.
- Added a Flutter widget regression test covering verified ammunition provenance, verified optic provenance, and the unsourced warning state.

## Verification in this environment

- Python offline regression suite: run separately for this build.
- Flutter/Dart tests: NOT RUN (Flutter/Dart SDK unavailable in this runtime).
- iOS build/Simulator/device: NOT RUN (Xcode/macOS unavailable in this runtime).
