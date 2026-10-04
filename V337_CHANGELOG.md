# V337 — Manual catalog persistence contract hardening

- Hardened `ManualCatalogStore` so standard rifle/ammunition records cannot be persisted or recovered without the required caliber value.
- Standard ammunition records now also require grain at the persistence boundary.
- Custom ammunition remains intentionally permissive because that workflow allows partial measurements.
- This closes a gap where UI-created records were validated by the form, but imported/migrated/programmatic records could bypass those required-field checks and survive storage validation.
- Added regression coverage in `tools/test_v337_manual_catalog_required_fields.py`.

Verification limitations remain unchanged: offline lint is not a Dart compiler/runtime test; real Flutter/iOS execution still requires Flutter/Xcode, and G1/G7 production acceptance remains closed until external py-ballisticcalc vectors exist.
