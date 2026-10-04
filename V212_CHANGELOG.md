# V212

- Continued from V211; no project restart.
- Added a fail-closed offline wheel-cache path to `tools/bootstrap_reference_validator.py` via `SNIPER_TURK_VALIDATOR_WHEEL_DIR`.
- Cached validator artifacts are selected solely by the SHA-256 values frozen in `validation/acceptance.json`; filenames are not trusted and exactly one matching wheel is required per package.
- Existing online PyPI metadata/download verification remains the default when no cache is configured.
- Added regression tests for cached hash selection and missing-policy-wheel rejection.
- This does **not** claim G1/G7 validation passed; actual pinned wheels/reference generation/comparison are still required before the production gate can open.
