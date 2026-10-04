# V364 — Compass reference correctness

- Independent audit found that the app overstated `flutter_compass 0.8.1` iOS readings as true north.
- Upstream package changelog says iOS uses magnetic heading by default since 0.4.0.
- Production UI now labels the current provider honestly as magnetic/sensor heading and does not claim geographic true north.
- No replacement true-north provider was added without build/device validation.
- Added `tools/test_v364_compass_reference_contract.py`.
- Ballistic solver and `validation/acceptance.json` untouched.
