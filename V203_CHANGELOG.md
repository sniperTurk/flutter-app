# V203 — lockfile adoption crash + partial-pair fix

Continued directly from V202; no project restart. No catalog, ballistics, or app UI changed.

## Fixed: `tools/adopt_verified_lockfile.py` could crash and leave a half-adopted pair

Reproduced directly (not inferred from reading the code): if installing the
*first* file (`pubspec.lock`) succeeded but installing the *second*
(`lockfile-provenance.txt`) then failed (e.g. its destination path turned out
to be a directory, or any other `OSError` mid-replace), the v202 implementation:

- raised an **uncaught `IsADirectoryError`** all the way out of `main()` —
  a raw traceback on stderr instead of this project's established clean
  `"LOCKFILE ADOPTION: BLOCKED\n- <message>"` contract (the same class of bug
  fixed for `verify_ios_privacy_manifests.py` in v182);
- left `pubspec.lock` **already overwritten** with the new content while
  `lockfile-provenance.txt` stayed on its old value — exactly the "mismatched
  pair" the function's own docstring claims can't happen ("the fail-closed
  verifier rejects the mismatched pair"). That's true only if something reruns
  the verifier afterward; the actual project files were left inconsistent by
  the crash itself.

Reproduction (before the fix): made the provenance destination an existing
directory, called `adopt()` — got an unhandled `IsADirectoryError` with
`pubspec.lock` already replaced and `lockfile-provenance.txt` untouched.

**Fix:** the two installs are now applied as a real unit. Before either
`os.replace`, any existing destination is backed up to a temp file. If either
replace fails, every destination this call touched is rolled back to its prior
content (or removed again, if it did not exist before) and a clean error is
returned — the function no longer raises for any `OSError`, and `main()` also
wraps the call so an unexpected exception can never surface as a crash either.
Backup temp files are cleaned up in every path, including when the backup
*copy itself* fails.

5 new regression tests reproduce the exact original crash (second-file
directory collision) and assert: no exception escapes `adopt()`, the first
file is rolled back to its prior content, a first-ever adoption with no
pre-existing files leaves no orphan, no temp files are left behind on failure,
and the CLI prints a clean `BLOCKED` message with no traceback.

## Reviewed and confirmed correct in v192–v202 (unchanged here)
- `lib/core/dope_ranges.dart`, `lib/features/ballistics/ballistics_screen.dart`
  (V194/V197 canonical 3000 m limit + atomic imperial-conversion parse-then-commit)
- `lib/core/catalog_search.dart` + `catalog_screen.dart` wiring (V195 Turkish
  fold/order-independent search)
- Catalog detail sheets (V193), MKE ammunition additions (V196)
- `tools/write_lockfile_provenance.py` / `verify_lockfile_provenance.py` /
  `app_store_preflight.py` provenance checks (V198–V200) — self-verifying,
  consistent key/hash contract
- `.github/workflows/bootstrap-lockfile.yml` now calls the canonical provenance
  writer instead of a duplicated hand-written implementation (V202) — confirmed
  no drift between the two
- `tools/run_physical_iphone_test.sh` before/after `pubspec.lock` hash gate (V192)

## Verification (executed here)
`python3 -m unittest discover -s tools -p 'test_*.py'`: **229/229 PASS** (v202: 224).
`compileall`: PASS. `verify_production_gate.py`: CLOSED.
`offline_dart_lint.py`: 55 files, 0 issues. `bash -n` on all 5 shell scripts: PASS.
Both workflow YAML files parse with PyYAML.

## Not verified
No Flutter/Dart SDK or network egress here. `dart format`, `flutter analyze`,
`flutter test`, Xcode build, Simulator/integration tests, physical-iPhone
testing, and xcarchive/App Store submission remain NOT RUN.
