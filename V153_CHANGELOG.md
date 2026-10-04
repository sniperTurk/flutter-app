# SNIPER TÜRK V1 — v153

## Production changes

- Strengthened catalog provenance as a production invariant: bundled branded rifle, ammunition, and optic records may no longer be silently shipped without `sourceName` + `sourceDocument`. Only explicit `Manuel` data-entry templates may remain unsourced.
- Reclassified the user-reported `G Maz No:30 Slug 51 gr` record as `Kullanıcı girdisi`; the UI now says `Doğrulama: kullanıcı girdisi` instead of implying manufacturer verification. No ballistic coefficient or drag model was invented.
- Expanded manufacturer-backed PCP ammunition coverage with four current JSB records across the 4.5 mm and 5.5 mm families: Exact .177 8.44 gr, Exact Heavy .177 10.34 gr, Exact Jumbo .22 15.89 gr, and Exact Jumbo Heavy .22 18.13 gr.
- Added Dart regression coverage for provenance enforcement, manual-template exceptions, and exact JSB caliber/weight pairs.
- Added an offline Python regression guard (`tools/test_v153_catalog_completeness.py`) so the same contracts are checked even in environments without Flutter/Dart.

## Source discipline

JSB values were checked against JSB Match Diabolo's current official catalog/product pages on 2026-09-27. No BC value is stored unless both the coefficient and drag model are explicitly supported by the source.

## Verification boundary

Offline Python/static checks can run in the current environment. `flutter analyze`, `flutter test`, iOS Simulator/device builds, signing, TestFlight, and hosted CI are not reported as passing unless they actually run in a suitable Flutter/macOS environment.
