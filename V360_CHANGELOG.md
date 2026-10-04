# V360 — lockfile bootstrap SHA manifest

- `bootstrap-lockfile.yml` now emits `lockfile-sha256.txt` containing SHA-256 values for both `pubspec.lock` and `lockfile-provenance.txt`.
- The manifest is uploaded with the bootstrap artifact, so the two hashes required for adoption can be copied without recomputing them manually.
- The workflow fails closed if the manifest does not contain exactly two lines.
- This does not claim that the workflow, Flutter analysis/tests, iOS build, Simulator, or physical-device tests have run.
