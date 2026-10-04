# V339 — Deep catalog mutation snapshots

## Fixed

V338 detached only the top-level caller-owned `Map` before queued catalog mutations. `Map.from()` is shallow, so an unknown/imported nested `Map` or `List` value could still be mutated by the caller after `save()` / `upsert()` returned but before the asynchronous persistence operation encoded the record. That left a nested TOCTOU alias despite the V338 top-level fix.

`UserCatalogStore` and `ManualCatalogStore` now create their queued mutation snapshot by JSON round-trip before crossing the asynchronous boundary. This detaches the full JSON-persistable value graph; validation and persistence operate on that detached snapshot.

## Regression coverage

Added `tools/test_v339_deep_catalog_snapshot.py`. Its two checks fail against V338's shallow `Map.from(entry)` implementation and pass with the deep snapshot helper.

## Scope / verification note

This change does not alter built-in catalog data or ballistic equations. Real Flutter/Dart execution still requires a Flutter SDK. The external G1/G7 production acceptance gate remains closed until the pinned py-ballisticcalc fixture can be generated and compared.
