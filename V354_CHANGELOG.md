# V354 — Reference fixture physical-domain hardening

- Hardened the canonical py-ballisticcalc fixture validator so finite-but-nonphysical values cannot pass the acceptance contract.
- Case inputs `bc`, `mv`, `grain`, `zero`, and `sight_mm` must now be strictly positive.
- Reference `range_m`, `velocity_mps`, and `time_s` must be strictly positive.
- Atmosphere pressure must be positive and humidity must be within 0..100 percent.
- Added regression coverage in `tools/test_v354_reference_physical_domain.py`.
- This does not generate reference vectors, relax tolerances, run the official Dart acceptance comparator, or open the production G1/G7 gate.
