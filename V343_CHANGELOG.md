# V343

- `manual_catalog_store.dart`: V341 required a non-empty `brand` for every record, but the manual-catalog dialog deliberately lets "Özel Yapım Mermiler" (custom ammunition) have an empty brand. Saving such a record failed with "Invalid identity field: brand", and any record stored earlier with an empty brand made `all()` throw for both the primary and the backup, so the whole manual catalog became unreadable. An empty brand is now valid only for `custom_ammunition`; type and the 100-character limit still apply to all identity fields, and whitespace-only brands stay rejected for rifles, ammunition and scopes.
- Added `tools/test_v343_custom_ammo_empty_brand.py`.
- Reviewed v336-v342 (deep snapshots, recovery repair queue, profile codec bounds) without finding other defects. Dart code was not run: no Flutter SDK here.
