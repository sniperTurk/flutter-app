# V186 — pinned lockfile bootstrap path

- Continued directly from V185; no project restart.
- Added a manual, read-only GitHub Actions workflow that can generate the missing `pubspec.lock` with the exact pinned Flutter 3.47.2 toolchain on macOS.
- The workflow deletes any stale lockfile, resolves dependencies, verifies the pinned toolchain, runs the resolver a second time and requires an identical SHA-256 before exporting the lockfile artifact.
- The workflow also rejects any unexpected `pubspec.yaml` mutation and has no repository write permission; adopting the generated lockfile remains an explicit reviewed source change.
- Added five dependency-free regression tests that lock the workflow's manual/read-only, exact-toolchain, deterministic-resolver and artifact contracts.
- This environment still cannot resolve the Flutter SDK host, so the generated lockfile itself, Dart formatting, Flutter analyze/test, Xcode, Simulator and physical iPhone remain NOT RUN / NOT VERIFIED.
