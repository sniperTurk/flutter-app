# SNIPER TÜRK V1 — v106

## Production work completed
- Continued from v105; no project restart.
- Expanded the manufacturer-backed FX Airguns 6.35 mm PCP catalog with current models: Impact M4, Crown MKII, Wildcat MKIII, DRS Classic MKII and DRS Pro MKII.
- Added only fields directly supported by current FX manufacturer pages. Variant-dependent reservoir/barrel/plenum values are left null when the page does not bind them unambiguously to the record.
- Added catalog regression assertions covering provenance and the deliberate absence of guessed variant data.

## Verification boundary
- Python validator regression suite and Python syntax checks can run in this environment.
- Flutter/Dart/Xcode are unavailable here, so flutter analyze/test and iOS build/Simulator/device results are NOT claimed as passed.
