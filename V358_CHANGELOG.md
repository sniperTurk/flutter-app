# V358 changelog

- Hardened `tools/validate_py_ballisticcalc_fixture.py` so the external G1/G7 acceptance fixture must match the four frozen generator scenarios exactly: case IDs, model/atmosphere mapping, BC, muzzle velocity, projectile weight, zero distance, sight height, atmosphere definitions, and exact range grids.
- Unknown case, atmosphere, case-level, and point-level fields are rejected fail-closed. Case list order remains non-semantic.
- Updated canonical validator test fixtures to the frozen scenarios and added V358 regressions for the previously accepted F1 drift cases.
- No solver, tolerance, atmosphere policy, production gate, or user-facing drag DOPE activation change. Production gate remains CLOSED.
