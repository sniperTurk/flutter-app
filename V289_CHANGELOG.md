# V289 — App Store Dart source symlink gate

- App Store capability preflight now rejects symlinked Dart source files in `lib/` and `integration_test/` instead of following them.
- Capability scanning now handles source `stat()` failures fail-closed rather than allowing an uncaught filesystem error.
- Added regression coverage for symlinked Dart source rejection.
- This is a source-side release-hardening change only; it does not claim a real Flutter/iOS build, Simulator run, or physical-device test.
