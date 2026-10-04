# V188 — lockfile artifact adoption safety

- Continued directly from V187; no project restart.
- Added `tools/verify_lockfile_provenance.py`, a fail-closed verifier for the generated lockfile artifact.
- The verifier requires exactly Flutter 3.47.2 provenance and checks that both `pubspec.yaml` and `pubspec.lock` SHA-256 values match the actual files; stale source, tampered lockfiles, duplicate keys, unknown keys, malformed hashes, and missing files are rejected.
- Wired the verifier into `bootstrap-lockfile.yml` before artifact upload, so a malformed provenance artifact cannot be published as trusted output.
- Added regression coverage for valid provenance, stale pubspec, tampered lockfile, wrong Flutter version, duplicate/unknown keys, and workflow ordering.
- Actual Flutter/Dart/Xcode/Simulator/physical-device execution remains NOT RUN / NOT VERIFIED in this environment.
