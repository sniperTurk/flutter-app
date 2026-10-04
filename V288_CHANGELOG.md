# V288

- Hardened App Store source preflight `.fvmrc` validation: parse JSON structurally instead of accepting a formatting-dependent substring.
- Fail closed on malformed JSON, non-object roots, and misleading embedded strings; require top-level `flutter` exactly `3.47.2`.
- Added regression coverage for malformed/non-object/misleading `.fvmrc` inputs.
- Validation: Python suite 347/347 PASS; compileall PASS; offline Dart lint PASS. Real Flutter/iOS build, Simulator, and physical-device tests were not run and remain unverified.
