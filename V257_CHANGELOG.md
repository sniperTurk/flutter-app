# V257 — Sight Height evidence retention hardening

- Continued from v256; no project reset.
- Sight Height photo replacement now removes the previous app-owned front/side evidence photo only after the replacement has been durably copied.
- Cleanup remains fail-safe and directory-scoped through `SightHeightPhotoStore.delete`; arbitrary external paths are never deleted.
- Added three regression guards for ordering, both photo roles, and app-owned path scoping.
- No Flutter/iOS build, Simulator run, or physical iPhone test is claimed by this change.
