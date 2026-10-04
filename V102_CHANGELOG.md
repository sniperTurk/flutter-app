# V102

- Made `RifleProfile.angularUnit` user-selectable (MRAD/MOA) in profile create/edit UI.
- Ballistics DOPE correction display now follows the profile angular-unit preference.
- Scope `clickUnit` remains independent and is used only for turret-click calculation.
- Made the persisted metric/imperial setting affect Ballistics inputs and result display while keeping the solver canonical SI internally.
- Added explicit SI/imperial conversion helpers and regression tests.
- Removed unreachable comma replacement in DOPE range token parsing.
- Renamed the settings toggle to clarify that it controls ballistic display/input units.
