# V268 CHANGELOG

## Lockfile provenance verifier fail-closed read hardening

- `tools/verify_lockfile_provenance.py` now converts malformed/non-UTF-8 provenance input into a clean BLOCKED error instead of allowing `UnicodeDecodeError` to escape.
- Hashing-time filesystem/read failures are now converted into a clean fail-closed verification error instead of propagating `OSError`.
- Added regression coverage for both malformed provenance encoding and hashing-time read failure.

## Verification performed in this environment

- Targeted provenance tests: 5/5 passed.
- Full offline Python unittest discovery: 369/369 passed.
- Python compileall: passed.
- Real Flutter/iOS build: not run.
- iOS Simulator: not run.
- Physical iPhone: not run.
- `pubspec.lock` + `lockfile-provenance.txt`: still absent from source package, so release lockfile gate remains BLOCKED.
