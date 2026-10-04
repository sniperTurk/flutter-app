# V328 changelog

- Hardened `tools/install_pinned_flutter.py` so replacement of an existing verified Flutter SDK is transactional.
- Existing SDK is atomically renamed to a same-parent backup before the final install move; if that move fails after creating a partial destination, the partial install is removed and the previous SDK is restored.
- Successful replacement removes the backup; rollback failure preserves the backup path and reports it explicitly instead of silently losing the prior SDK.
- Added regression coverage for failed-final-move rollback and successful replacement cleanup.
- Real Flutter/Xcode/iOS execution remains unverified in this environment.
