# V318 — Full-source persistence hardening audit

## Fixed
- PersistentProfileStore no longer treats a missing primary as an empty profile list when a valid backup survives; it recovers and self-heals the primary.
- The first successful profile write now creates a recoverable backup immediately.
- Corrupt or empty persisted primary data without a valid backup now fails closed instead of being misread as an empty profile collection.
- A failed first profile primary write rolls back the newly-created uncommitted backup.
- UserCatalogStore save/remove now use a shared backup-first commit path; backup failure cannot leave a changed primary while reporting failure, and primary failure restores the previous backup when possible.

## Regression coverage
- Added offline v318 profile recovery/first-write/rollback guards.
- Added executable Flutter profile-store tests for missing-primary recovery, first-write backup, corrupt-primary-without-backup, and empty-primary corruption. These are source-added but were not executed in this environment because Flutter/Dart SDK is unavailable.
- Added offline v318 UserCatalogStore atomic-commit guards.

## Verification in this environment
- Python unittest discovery: 408/408 PASS.
- Offline Dart lint: 59 Dart files, 0 issues.
- Python compileall: PASS.
- Shell syntax checks: PASS.
- Flutter analyze/test/format and Xcode/Simulator/device validation: NOT RUN (toolchains unavailable here).
