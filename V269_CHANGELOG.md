# V269 CHANGELOG

## Production change
- Hardened `tools/verify_lockfile_provenance.py` at the release trust boundary.
- `pubspec.yaml`, `pubspec.lock`, and `lockfile-provenance.txt` are now rejected if any is a symbolic link; verification no longer follows symlinked trust inputs.
- Filesystem inspection errors remain fail-closed.

## Regression coverage
- Added three tests covering symlinked pubspec, lockfile, and provenance inputs.
- Targeted verifier suite: 8/8 passed.
- Full offline Python suite: 372/372 passed.
- Python compileall: passed.

## Still blocked / not claimed
- No real `pubspec.lock` + provenance pair was generated in pinned Flutter 3.47.2 during this run.
- No real Flutter/iOS build was run.
- No iOS Simulator test was run.
- No physical iPhone test was run.
- Independent G1/G7 trajectory acceptance remains pending.
