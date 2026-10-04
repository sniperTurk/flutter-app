# V350

- Removed the stale second ballistic reference-fixture contract from the legacy `tools/validate_ballistic_reference_vectors.py` entry point.
- The legacy command now delegates to the canonical `validate_py_ballisticcalc_fixture.validate`, so it accepts exactly the same `cases`/`points` schema produced by `generate_reference_vectors.py` and consumed by the Dart comparator.
- Reworked the v262 regression test to prove that the canonical fixture passes, the obsolete `vectors` shape fails closed, and embedded acceptance-policy drift is rejected.
- No production G1/G7 activation change: the gate remains closed until independently generated py-ballisticcalc vectors pass the declared comparison.
