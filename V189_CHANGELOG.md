# V189 — verified lockfile adoption path

- Continued directly from V188; no project restart.
- Added `tools/adopt_verified_lockfile.py` so the Flutter 3.47.2 lockfile artifact can be installed into the source tree only after the existing fail-closed provenance contract succeeds.
- Adoption verifies the current `pubspec.yaml` hash, artifact `pubspec.lock` hash, exact Flutter 3.47.2 provenance, and then installs the lockfile with an atomic replace.
- A stale-source or tampered artifact is rejected without overwriting an existing project lockfile.
- Added regression coverage for valid adoption, stale source protection, tampered artifact rejection, and missing provenance rejection.
- Actual Flutter/Dart/Xcode/Simulator/physical-device execution remains NOT RUN / NOT VERIFIED in this environment.
