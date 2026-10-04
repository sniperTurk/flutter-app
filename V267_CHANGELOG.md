# V267 — lockfile adoption symlink hardening

Continues V266 without restarting the project.

## Production change
`tools/adopt_verified_lockfile.py` now fails closed when either downloaded lockfile artifact member (`pubspec.lock` or `lockfile-provenance.txt`) is a symbolic link, preventing adoption from following artifact-controlled paths outside the bundle. It also refuses pre-existing project-root symlink destinations so backup/rollback cannot silently change filesystem object semantics or touch a symlink target.

## Regression coverage
Added three tests covering symlinked artifact lockfile, symlinked provenance, and a project destination symlink whose target must remain untouched.

## Verification
- targeted adoption suite: 17/17 passed
- full offline Python suite: 369/369 passed
- Python compileall: passed
- no Flutter/macOS/iOS build, Simulator, or physical-device result was produced in this environment
- `pubspec.lock` + `lockfile-provenance.txt` are still absent; release/iOS gate remains blocked until the pinned Flutter 3.47.2 bootstrap workflow produces and the verifier adopts that pair
