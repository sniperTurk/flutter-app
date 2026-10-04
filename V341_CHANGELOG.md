# V341

- Hardened `ManualCatalogStore` persistence validation for user-owned catalog identity fields.
- `id`, `brand`, and `model` must now be non-empty after trimming and at most 100 characters, matching the stronger `UserCatalogStore` boundary.
- This closes a path where whitespace-only brands or unbounded identity strings could be persisted through import/programmatic flows even though the UI/user catalog boundary rejects them.
- Added `tools/test_v341_manual_catalog_identity_validation.py` regression coverage.
