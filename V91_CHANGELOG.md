# V91 Change Log

## Independent G1/G7 validation harness repair

- Corrected `generate_reference_vectors.py` to use the documented py-ballisticcalc 2.2.x object model:
  - projectile weight belongs to `DragModel`, not `Ammo`;
  - `set_weapon_zero` receives a configured `Shot` plus zero distance;
  - the reference shot now explicitly uses `Atmo.icao()`.
- Removed the unused `zero_angle_rad` fixture field rather than relying on an unverified unit-object cast.
- Added explicit ICAO sea-level atmosphere provenance to the generated fixture.
- Hardened the Dart comparator so it rejects a stale fixture generated under a different acceptance policy or atmosphere.

These changes repair the validation harness only. They do not constitute a passed G1/G7 cross-validation. The production drag gate remains closed until the pinned independent package and Dart comparator actually run successfully in CI.
