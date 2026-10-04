# V359 — Acceptance integrity hardening

- Canonical fixture validator now rejects unknown top-level fields fail-closed.
- Reference generator now sources frozen cases, ranges and atmospheres from the canonical validator contract, removing duplicated scenario constants that could drift offline.
- Official Dart comparator now invokes the canonical Python fixture validator before reading/comparing vectors, so direct comparator use cannot bypass frozen-scenario or unknown-field checks.
- Added `tools/test_v359_acceptance_integrity.py` regression coverage.
- Solver, frozen tolerances, atmosphere policy, production gate and user-facing drag DOPE activation are unchanged. Production G1/G7 gate remains CLOSED.
