# V335

Independent full-source audit of v334 (same sources as the delivered v334 zip).

- `ballistics_screen.dart`: the vacuum baseline returns muzzle velocity and muzzle energy at every range, but the table column was headed "Enerji J / ft-lb", so a user could read muzzle energy as retained energy at 300 m. The column is now "Namlu enerjisi" with an asterisk, and the footnote states that air drag is not modelled, drops at long range are underestimated, the energy column is constant, and the output must not be used for real shooting.
- Added `test_v335_vacuum_table_labels.py`.
- Audited without finding defects: G1/G7 Cd tables (79/84 points, sampled values match the standard BRL/JBM tables), vacuum zero-angle algebra, unit conversions, atmosphere/drag equations (offline cross-check passes), settings and active-profile stores.
- Not verifiable here: Flutter analyze/test, Xcode/iOS build, the external py-ballisticcalc acceptance run. The G1/G7 production gate remains CLOSED.
