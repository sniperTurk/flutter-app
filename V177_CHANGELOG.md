# V177 changelog

- Hardened scope adjustment-range provenance: a lower-bound flag now fails catalog integrity unless its corresponding MRAD range exists.
- Added Dart regression coverage for both orphaned lower-bound metadata and valid published lower-bound ranges.
- Added an offline Python contract so CI discovery protects the new fail-closed semantics even before Flutter is available.
- No Flutter/Xcode/Simulator/device result is claimed by this change.
