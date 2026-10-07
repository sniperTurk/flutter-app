# Independent trajectory validation

G1/G7 production activation is allowed only while SNIPER TÜRK output is compared with independently generated trajectory vectors on every CI run. The gate was opened in V355: `BallisticEngine.solve` now sends requests with a ballistic coefficient and drag law to `AerodynamicTrajectorySolver`. `tools/verify_production_gate.py` fails the build if the engine falls back to the vacuum solver for such a request, or if the no-wind and wind reference comparison steps disappear from `.github/workflows/ios-ci.yml`.

Reference implementation selected: `py-ballisticcalc==2.2.10` (Ballistics Lab). The generator in `tools/generate_reference_vectors.py` is deliberately external to the Dart solver and writes a JSON fixture with its implementation/version and all input conditions. The generated fixture is **never git-committed** (`validation/py_ballisticcalc_vectors.json` is in `.gitignore`, so a stale or hand-edited copy cannot be mistaken for a live validator run); CI regenerates it from scratch on every run, uploads it as a build artifact for human review, and immediately runs the Dart comparison against that same fresh copy in the same job.

This repository does **not** contain generated reference values yet, and will not accumulate a historical copy in git. A missing Python dependency or unavailable network is not treated as a validation pass.

Required acceptance before activation:
- G1 and G7 cases.
- Calm standard-atmosphere baseline plus at least one non-standard atmosphere.
- Multiple ranges spanning subsonic/transonic/supersonic regimes where applicable. The frozen policy requires G1 coverage through at least 300 m and G7 coverage through at least 1500 m so the rifle reference set is not limited to near-muzzle supersonic flight.
- Compare drop/correction, velocity and time of flight; wind vectors are a separate acceptance set because the implementations use different wind conventions.
- Tolerances must be declared before seeing comparison results; do not widen them merely to make a failing case pass.

## Frozen acceptance policy

`validation/acceptance.json` is the reviewable, machine-readable acceptance policy. Its numerical tolerances are committed **before** reference output is available, preventing result-driven tolerance widening. It also pins the expected 2.2.10 wheel SHA-256 published by PyPI. Generating vectors does not itself open the production gate: the freshly generated fixture still has to be compared with the Dart solver in the same CI run and all declared tolerances must pass.

## Automated Dart comparison

`dart run tools/compare_reference_vectors.dart` is the fail-closed consumer of the
independent fixture. It verifies fixture provenance/version and required G1/G7
coverage, runs `AerodynamicTrajectorySolver` under the same dry ICAO standard
atmosphere, and compares height, velocity, and time-of-flight against the
predeclared tolerances in `acceptance.json`. CI runs this comparison before
format/analyze/tests. A missing fixture, malformed fixture, missing model, or any
out-of-tolerance point exits non-zero; it never opens the production gate by
itself.

### Offline validator bootstrap

For an offline/restricted runner, place the four policy-pinned wheel files in a directory and set
`SNIPER_TURK_VALIDATOR_WHEEL_DIR` to that directory before running
`python3 tools/bootstrap_reference_validator.py`. The bootstrap does not trust filenames: every
cached wheel is selected by the SHA-256 already frozen in `acceptance.json`, requires exactly one
match per package, and pip still installs with `--no-index --no-deps`. If the variable is absent,
the existing PyPI-metadata + verified-download path is used.
