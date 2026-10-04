# V347 changelog

- Fixed `tools/compare_reference_vectors.dart` so acceptance policy and independent reference fixture paths are resolved from the comparator script location, not the caller working directory.
- Added `tools/test_v347_reference_comparator_path.py` to lock the cwd-independent validation contract.
- G1/G7 production gate remains closed; no reference vectors were fabricated or accepted.
