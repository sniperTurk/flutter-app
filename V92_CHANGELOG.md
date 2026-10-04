# v92 production validation hardening

- Locked the independent py-ballisticcalc trajectory generator to the explicit `rk4_engine` instead of relying on the package default.
- Added the engine identity to generated reference-fixture provenance and made the Dart comparison fail closed unless that exact engine is recorded.
- Pinned CI Python to 3.12.11 and records the Python version with Flutter/Dart/Xcode, reducing validator drift from macOS runner image changes.
- These changes harden reproducibility only; they do not claim that G1/G7 comparison, Flutter tests, or iOS builds have passed.
