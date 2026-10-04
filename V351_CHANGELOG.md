# V351

- Added `tools/report_reference_vector_differences.py`, a diagnostic-only per-case/per-range report for an independently generated `py_ballisticcalc_vectors.json` fixture.
- The reporter validates the canonical fixture contract first, uses the existing Python port of the SNIPER TÜRK no-wind solver, prints absolute height/velocity/time differences against the frozen acceptance tolerances, and exits non-zero when any point exceeds them.
- It explicitly performs no gate action and does not modify the acceptance policy or fixture. Official production acceptance remains `tools/compare_reference_vectors.dart` under a real Dart/Flutter SDK.
- Added v351 regression tests for fail-closed contract handling and no-policy-mutation behavior.
