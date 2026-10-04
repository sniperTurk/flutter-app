# v94 production validation hardening

- Closed a remaining supply-chain reproducibility gap in the independent G1/G7 validator: every direct runtime wheel used by `py-ballisticcalc==2.2.10` is now frozen by both exact version and SHA-256 in `validation/acceptance.json`.
- `bootstrap_reference_validator.py` now resolves only a PyPI universal wheel whose metadata hash matches policy, downloads each artifact, re-hashes its bytes locally, and installs the verified local wheel set with `pip --no-index --no-deps`. Pip is no longer allowed to fetch resolver-selected dependency artifacts during validator installation.
- `generate_reference_vectors.py` validates the new version+hash dependency-lock schema before generating a fixture; because the full acceptance policy is embedded in the fixture, the Dart comparator also binds comparison to this lock set.
- Hashes were checked against PyPI release metadata on 2026-09-25. This hardening does not claim that independent trajectories or Flutter/iOS builds passed in the current environment.
