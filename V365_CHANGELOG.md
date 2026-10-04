# V365 — lockfile bootstrap production validation

- Continues from V364; no project restart.
- Strengthens `.github/workflows/bootstrap-lockfile.yml`: the generated lockfile is no longer uploaded until the same pinned Flutter 3.47.2 job passes Dart formatting, `flutter analyze --fatal-infos --fatal-warnings`, and `flutter test --reporter=expanded`.
- Adds `tools/test_v365_lockfile_bootstrap_flutter_validation.py` to keep validation before artifact upload and pin it to the same workflow/toolchain.
- Does not modify ballistic solver, acceptance policy, catalog data, or UI behavior.
- Local Linux environment still cannot execute Flutter/Xcode; these new CI steps are therefore NOT RUN locally and must not be reported as passed.
