# V349

- `tools/offline_solver_crosscheck.py` still sampled every case out to 300 m, so the v348 change that extends G7 reference sampling to 1500 m was not covered by the offline check. It now uses the same per-model ranges as `generate_reference_vectors.py` (G1 to 300 m, G7 to 1500 m) and a test ties them to `minimum_max_range_m_by_model` in `validation/acceptance.json`.
- Result at the new ranges: the Dart-style RK4 and an independent DOP853 integration agree to about 3e-6 m (height), 3e-6 m/s (velocity) and 1.3e-8 s (time); coarse-step convergence is better than 1e-4 m. The G7 rifle cases reach about 47-49 m of drop and 263-274 m/s at 1500 m.
- Reviewed v347/v348: comparator paths resolved from the script location, `minimum_max_range_m_by_model` enforced in both the Python validator and the Dart comparator, tolerances unchanged. No defect found.
- Note for the gate owner: the frozen absolute height tolerance (0.01 m) now applies at 1500 m, where drop is roughly 47-49 m (about 0.02 %). Tiny differences in air-density formulation between py-ballisticcalc and this solver can approach that. A failed comparison keeps the gate closed (safe), so the tolerance was left unchanged; it should only be revisited from real reference output, not beforehand.
- The G1/G7 production gate remains CLOSED. Dart code was not run: no Flutter SDK here.
