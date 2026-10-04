# SNIPER TÜRK V1 — v143

## Production work completed

- Replaced the unsourced generic AirMaks `Krait` 6.35 catalog row with two exact current manufacturer configurations: Krait S and Krait MK2 S.
- Added manufacturer-backed 6.35 metadata for magazine capacity, barrel length/type, air capacity, overall length, weight, plenum, optics rail and moderator thread.
- Added Dart catalog regression coverage plus an offline Python provenance regression wired into iOS CI, so the generic placeholder cannot silently return.

## Verification in this environment

- Offline Python regression suite executed locally.
- Python verification tools compiled locally.
- GitHub Actions YAML parsed locally.
- iOS bootstrap shell syntax checked locally.
- G1/G7 production gate executed locally.
- Real Flutter/Dart/Xcode execution is unavailable in this environment and is not claimed as successful.
