# V297

- Added validated backup storage for UserCatalogStore writes/removals.
- UserCatalogStore now falls back to the backup only when the primary catalog fails validation.
- A fully validated backup self-heals the corrupt primary catalog before returning data.
- Added a Flutter regression test for corrupt-primary / valid-backup recovery.
- No Flutter/iOS runtime result is claimed because Flutter SDK/Xcode are unavailable in this environment.
