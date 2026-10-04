# V231 — Sight Height approval/data consistency

Based on inspected v230 source. This release does **not** contain the separately described but unavailable alternative v226 implementation.

- Editing any calibration/measurement field invalidates the previously calculated result and both approval checkboxes.
- Recalculation clears previous approval; persistence uses a snapshot of the inputs used in the calculation, not later mutable text-field contents.
- Saving is single-flight to prevent duplicate writes.
- Added source-contract regression tests.

Flutter/Dart compile, real iOS build, Simulator and device tests remain unverified unless separately executed on a compatible toolchain.
