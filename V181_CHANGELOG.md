# V181 CHANGELOG

## Production hardening
- Hardened `tools/verify_ios_privacy_manifests.py` so archive privacy evidence is accepted only from the built `Products/Applications/Runner.app` payload, not arbitrary xcarchive locations such as dSYMs.
- Required-reason declarations now fail closed unless the API category/reason pair is recognized by the application's current dependency contract (`NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1`). Arbitrary non-empty strings no longer satisfy the release gate.
- Added regression coverage proving an out-of-app manifest and an unknown reason code cannot turn the archive gate green.
- Updated privacy-gate fixtures to model the actual Runner.xcarchive application layout.

## Verification performed in this environment
- `python3 -m compileall -q tools`: PASS
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 146/146 PASS
- `python3 tools/offline_dart_lint.py`: PASS (53 Dart files, 0 issues)
- `python3 tools/verify_production_gate.py`: CLOSED/PASS
- Real Flutter analyze/test, Xcode build, Simulator and physical-device execution were NOT run in this environment.
