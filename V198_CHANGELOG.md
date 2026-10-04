# V198
- Hardened the local first-resolver bootstrap: a newly generated `pubspec.lock` now gets deterministic provenance tied to Flutter 3.47.2 and the exact `pubspec.yaml`/lockfile SHA-256 values.
- The local verification chain now fail-closes if provenance generation or verification fails, before format/analyze/test can be treated as passing.
- Added regression coverage for valid provenance, wrong-Flutter rejection, and verification ordering.
- No Flutter/Xcode/iOS execution is claimed in this environment.
