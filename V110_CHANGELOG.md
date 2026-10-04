# SNIPER TÜRK V1 — v110

- Independent G1/G7 acceptance policy now explicitly requires the full model × atmosphere cross-product.
- Dart reference comparator tracks and rejects missing G1/G7 × ICAO/hot-high combinations instead of accepting independent set coverage.
- Python production-gate verifier enforces the cross-product policy and gains an offline regression test.
- Reference generator refuses to emit fixtures when the cross-product requirement is absent.
- Production aerodynamic gate remains closed; no independent comparison is claimed in this environment.
