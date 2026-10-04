# V213

- Continued from V212; no project restart.
- Fixed a profile persistence data-loss risk in `ProfileDocumentCodec`: malformed records are no longer silently dropped from an otherwise readable collection.
- The codec now fails closed on any malformed/non-map record so `PersistentProfileStore` can use its existing backup-recovery path instead of later overwriting storage with a partial profile set.
- Duplicate valid profile ids remain deterministic (last valid record wins) and are not treated as corruption.
- Updated Flutter codec regressions and added an offline source-contract regression guard.
- No claim is made that Flutter/Xcode tests ran in this environment.
