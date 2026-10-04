# V340 changelog

- Hardened `ManualCatalogStore` recovery: a missing/corrupt primary is now repaired from a validated backup instead of leaving the store permanently dependent on backup reads.
- Serialized recovery writes with `upsert`/`remove` through the same process-wide mutation queue so stale recovery cannot overwrite a newer concurrent mutation.
- Mutations now call the private `_read()` while already inside the queue, preventing recursive queue deadlock during recovery.
- Added `tools/test_v340_manual_catalog_recovery_repair.py` and strengthened the older v223 recovery contract.
- No G1/G7 production gate status change: external py-ballisticcalc acceptance vectors are still absent.
