# V336 — User catalog optional rifle numeric validation

- Fixed a fail-closed validation gap in `UserCatalogStore`: optional rifle fields `barrelLengthMm` and `airCapacityCc` are now validated as finite positive numbers when present.
- Previously a malformed persisted/user-supplied value (for example a string barrel length) could pass `validate()` and later fail with a runtime type cast in `rifle()`.
- Added a Dart regression test for malformed optional rifle numeric fields.
- Added an offline Python source-contract regression so the guard remains testable when Flutter/Dart SDKs are unavailable.
- No G1/G7 production gate status change; independent `py-ballisticcalc` vectors are still required.
