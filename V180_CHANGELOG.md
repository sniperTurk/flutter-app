# V180 — repair invalid CI workflow introduced in v179

Continues from v179; no project restart. No app code, catalog or ballistics changed.

## Fixed: `.github/workflows/ios-ci.yml` was not valid YAML in v179
The v179 archive-`MinimumOSVersion` check added a `python3 - <<'PYMINIOS'`
heredoc inside a `run: |` block, but the heredoc body and terminator were at
column 0. That ends the YAML block scalar early, so the file fails to parse
(PyYAML: "could not find expected ':'", line 274) and GitHub Actions would
refuse to start *any* job — the whole iOS pipeline would have been dead. The
v179 tests only grepped the workflow text, so nothing noticed.

Fix: the six heredoc lines are indented to the block's indentation (YAML strips
it, the shell still sees the heredoc at column 0).

## Added: `tools/test_ci_workflow_yaml_integrity.py`
- Dependency-free block-scalar check (works on runners without PyYAML) that
  flags non-YAML text escaping a `run: |` block; verified to flag the v179 file
  at line 274 and to pass v180.
- Regression test for the checker itself (broken vs fixed heredoc).
- `yaml.safe_load` parse of every workflow when PyYAML is present.
- Extracts the real `PYMINIOS` script from the workflow and executes it:
  15.0 / 15 / 17.2 pass; 14.0 / 13.0 / malformed are rejected.

## Reviewed and confirmed in v179 (unchanged)
Raising the iOS floor 13 -> 15 (`app_store_preflight.py`, scaffold check,
archive `MinimumOSVersion` gate, tests) is consistent across all files and
matches upstream: Flutter 3.47+ requires iOS 15 (flutter/flutter#187741;
plugin release notes state "minimum iOS deployment target is now 15.0, as
required by Flutter 3.47+"). No stale 13.0 references remain outside changelogs.

## Verification (executed here)
See the test/gate results in the delivery message. Flutter/Xcode/Simulator/device
steps were NOT run (no SDK, no network egress); the workflow has still never
been executed by GitHub Actions.
