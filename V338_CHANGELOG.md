# V338 — Catalog mutation snapshot hardening

- Fixed a TOCTOU/data-integrity gap in `UserCatalogStore.save`: caller-owned mutable maps are now snapshotted before entering the asynchronous mutation queue, and the snapshot is the value validated and persisted.
- Applied the same snapshot boundary to `ManualCatalogStore.upsert`; the snapshot is validated before enqueue and again at the mutation boundary.
- This prevents a caller from changing an entry after `save`/`upsert` is invoked but before a queued persistence operation runs, which could previously make validation and persistence observe different data.
- Added `tools/test_v338_catalog_mutation_snapshot.py` as a regression contract.
- No ballistic model, catalog provenance, or UI behavior was intentionally changed.
