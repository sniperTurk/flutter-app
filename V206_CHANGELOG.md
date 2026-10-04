# V206 CHANGELOG

Base: V205. Project was not restarted.

## Production regression hardening

- Added a combined failure-injection regression for `tools/adopt_verified_lockfile.py` where **both** rollback restores fail in the same transaction after post-install provenance verification fails.
- Locks the V205 recovery contract: both original backups must survive cleanup, both recovery paths must be reported, and adoption must return a controlled error instead of raising.
- No production-code behavior changed because V205 already handled this combined case correctly; V206 makes that behavior permanent and regression-protected.

## Verification actually run

- Python offline unittest discovery: 233/233 PASS.
- `python3 -m compileall -q tools`: PASS.
- Production gate: CLOSED/PASS.
- Offline Dart lint: PASS (55 files, 0 issues).
- All `tools/*.sh`: `bash -n` PASS.
- GitHub Actions workflow YAML parsing: PASS.

## Not run / not claimed

No real Dart/Flutter/Xcode environment was available. `dart format`, `flutter analyze`, `flutter test`, real iOS build, iOS Simulator, physical iPhone, and xcarchive/IPA remain NOT RUN / unverified.
