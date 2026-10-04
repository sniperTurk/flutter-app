# V205 — rollback recovery preservation

Base: V204. No project restart.

## Production defect fixed
`tools/adopt_verified_lockfile.py` correctly reported a rollback failure in V204, but its unconditional cleanup then deleted the backup file whose restore had just failed. In the rare but critical rollback-of-rollback path, this could destroy the only preserved copy of the pre-adoption lockfile/provenance state.

V205 tracks backups whose restore fails, leaves those recovery copies on disk, and includes their exact path in the fail-closed error. Backups are still deleted after successful rollback/commit paths.

## Regression coverage
Added a fault-injection test that lets both installs complete, forces post-install verification failure, then forces restoration of the original `pubspec.lock` to fail. It proves the original bytes survive in the reported backup instead of being deleted by cleanup.

Real Flutter/Xcode/Simulator/device validation is not claimed by this change.
