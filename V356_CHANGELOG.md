# V356 — reference generator CI interpreter fix

- Fixed a release-CI blocker in the independent py-ballisticcalc acceptance path.
- `bootstrap_reference_validator.py` deliberately installs the pinned/hash-verified validator into `.validator_venv`.
- `generate_reference_vectors.py` deliberately refuses to run unless `sys.prefix` is exactly that venv.
- CI previously invoked the generator with host `python3`, so a successful bootstrap was followed by a guaranteed fail-closed generator rejection.
- CI now invokes `.validator_venv/bin/python tools/generate_reference_vectors.py`.
- Added regression coverage locking bootstrap/generator interpreter parity.
- No solver equations, tolerances, UI activation, or production gate policy changed.
