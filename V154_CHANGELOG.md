# SNIPER TÜRK V1 — v154

## Production catalog expansion

v154 continues from v153 and expands the production catalog only with manufacturer-backed records.

### Added rifles
- AirMaks Arms Krait MK2 PRO X HP 6.35 mm — official AirMaks product specifications.
- FX Airguns Dreamline Classic 4.5 mm — official FX brochure.
- FX Airguns Dreamline Classic 5.5 mm — official FX brochure.
- FX Airguns Dreamline Classic 6.35 mm — official FX brochure.

The FX Dreamline entries are deliberately caliber-specific because magazine capacity, barrel length and air capacity differ by caliber. Synthetic-stock weight is used consistently and is stated in each record's provenance text.

### Added optics
- Arken EP-5 GENII 5–25×56 FFP VPR MRAD.
- Arken EP-5 5–25×56 FFP VPR MRAD.

Values are taken from Arken Optics USA's official EP-5 comparison table. MOA variants are not conflated with the MRAD records.

### Regression protection
`tools/test_v154_catalog_expansion.py` locks the six new IDs, key manufacturer specifications, provenance presence, and minimum catalog counts.

### Verification boundary
Offline Python regression checks can be run in this repository. `flutter analyze`, `flutter test`, iOS Simulator/device builds and App Store signing remain unverified unless run on a real Flutter/Xcode environment.
