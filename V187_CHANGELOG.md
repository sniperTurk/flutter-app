# V187 — lockfile provenance hardening

- Continued directly from V186; no project restart.
- Hardened the manual pinned-Flutter lockfile bootstrap so its artifact now includes `lockfile-provenance.txt`.
- Provenance records the exact Flutter 3.47.2 toolchain plus SHA-256 of both `pubspec.yaml` and generated `pubspec.lock`, making stale/mismatched resolver artifacts detectable before adoption.
- Added fail-closed hash-shape checks and two regression tests locking the provenance/artifact contract.
- The actual `pubspec.lock` still cannot be generated in this environment because Flutter is unavailable; Dart/Flutter/Xcode/Simulator/physical-device results remain NOT RUN / NOT VERIFIED.
