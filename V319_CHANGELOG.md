# V319 — independent persistence audit

- Serialized `UserCatalogStore` recovery writes with save/remove mutations and re-read storage after entering the queue, preventing a stale backup recovery from overwriting a newer concurrent catalog mutation.
- Added red/green regression coverage for user-catalog recovery serialization.
- Made `ManualCatalogStore` primary-write failure restore the previous backup, so a failed first mutation cannot later reappear from backup as if it had succeeded.
- Added red/green regression coverage for manual-catalog backup rollback.
- No real Flutter/Xcode/iOS build claim is made by this change.
