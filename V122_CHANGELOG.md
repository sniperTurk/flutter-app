# V122 — 2026-09-26

## Manufacturer-verified PCP ammunition expansion

- Added three JSB Match Diabolo .25 / 6.35 mm Exact King-family pellet records to the production catalog: Exact King, Exact King Heavy, and Exact King Heavy MKII.
- Source weights are manufacturer-published metric values (1.645 g and 2.200 g); catalog grain values are deterministic unit conversions rounded to two decimals (25.39 gr and 33.95 gr).
- No ballistic coefficient or drag model was invented.
- Added a Flutter catalog regression test that locks caliber, weight, projectile type, provenance, and null-BC behavior for these records.

## Verification in this environment

- Python offline regression suite: run separately for this build.
- Flutter/Dart tests: NOT RUN (Flutter/Dart SDK unavailable in this runtime).
- iOS build/Simulator/device: NOT RUN (Xcode/macOS unavailable in this runtime).
