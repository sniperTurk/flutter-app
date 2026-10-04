# V266

- Continued from v265; no project restart.
- Added `tools/validate_py_ballisticcalc_fixture.py`, a strict validator for the actual schema emitted by `generate_reference_vectors.py`.
- Validator checks frozen acceptance-policy equality, pinned generator/version/engine, atmosphere definitions, finite case/point values, unique case IDs, strictly increasing ranges, minimum coverage, and full G1/G7 x atmosphere cross-product.
- Wired this validator into iOS CI immediately after independent vector generation and before artifact upload/Dart numerical comparison.
- Added four regression tests covering valid schema, missing cross-product, policy drift, and duplicate/unsorted data.
- Full offline Python suite: 366/366 passed.
- Offline Dart lint: PASS (78 files, 0 issues).
- Closed production G1/G7 gate verification: PASS (gate remains intentionally closed).
- Independent validator bootstrap was attempted but blocked by DNS/network; no trajectory vectors were generated and no numerical comparison was claimed.
- Lockfile provenance remains BLOCKED because pubspec.lock and lockfile-provenance.txt are absent in this source package.
- No real Flutter/iOS build, Simulator, or physical iPhone test was run.
