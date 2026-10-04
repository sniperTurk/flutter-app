# V200

- Hardened iOS release CI so the committed dependency lockfile provenance is verified before Flutter is installed or dependency resolution runs.
- CI now fail-closes early if `lockfile-provenance.txt` is absent/malformed, declares a Flutter version other than 3.47.2, or does not match the current `pubspec.yaml` / `pubspec.lock` SHA-256 values.
- Added three regression assertions locking the CI ordering and provenance gate.
- The source package still does not contain a generated `pubspec.lock`; therefore real Flutter/iOS release gates remain blocked until a lockfile is generated with pinned Flutter 3.47.2 and adopted with matching provenance.
- No Flutter/Xcode/Simulator/physical-iPhone execution is claimed in this environment.
