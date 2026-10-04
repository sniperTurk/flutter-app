# V121 — 2026-09-26

## Production verification repair

- Corrected a malformed Dart source artifact in `test/profile_store_test.dart` introduced in v120: the two new corruption regression tests had literal `\\n` escape text written between statements instead of real line breaks.
- This defect would prevent the Dart/Flutter test file from parsing, so the v120 corruption regression tests could not have been executable as written.
- No production behavior was claimed from those malformed tests; the underlying fail-closed `PersistentProfileStore` implementation from v120 is retained unchanged.
- Re-scanned `lib/` and `test/` for literal escaped-newline artifacts after the repair; remaining `\\n` occurrences are intentional string literals.

## Verification in this environment

- Python offline regression suite: 16/16 PASS.
- Flutter/Dart tests: NOT RUN (Flutter/Dart SDK unavailable in this runtime).
- iOS build/Simulator/device: NOT RUN (Xcode/macOS unavailable in this runtime).
