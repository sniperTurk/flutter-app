# V202 changelog

- Removed the duplicate hand-written lockfile provenance implementation from `.github/workflows/bootstrap-lockfile.yml`.
- The bootstrap workflow now calls the canonical `tools/write_lockfile_provenance.py --flutter-version 3.47.2`, the same fail-closed writer used by local bootstrap.
- Added regression coverage requiring the canonical writer to run only after the second `flutter pub get` proves resolver stability, and forbidding reintroduction of workflow-local hash/provenance generation.
- No Flutter/Xcode/iPhone execution is claimed by this release.
