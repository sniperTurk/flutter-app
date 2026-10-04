# V298

- `user_catalog_store.dart`: V297 recovered from a corrupt primary but still returned `[]` when the primary key was missing and a valid backup existed. The next `save()` would then overwrite the backup too, destroying the last copy. A missing primary now restores from the validated backup (same behavior as `ManualCatalogStore`).
- Added a Dart regression test for missing-primary / valid-backup.
- No Flutter SDK here: Dart tests were not run.
