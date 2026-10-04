# V291_CHANGELOG

- Continued from v290; no project restart.
- Hardened App Store lockfile provenance verification against filesystem I/O races.
- Added `_sha256_file()` fail-closed hashing: an `OSError` while hashing `pubspec.yaml` or `pubspec.lock` now becomes a deterministic provenance mismatch instead of an uncaught traceback.
- Added regression coverage simulating a `pubspec.lock` read failure during digest verification.
- Verification: full Python unittest discovery passes; `compileall` passes; offline Dart lint passes on 58/58 Dart files.
- Real Flutter analyze/test, Xcode build, Simulator and physical iPhone tests were not run and are not claimed successful.
