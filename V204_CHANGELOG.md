# V204 — lockfile adoption commit-after-verify fix

Continued directly from V203; no project restart.

## Fixed
V203 correctly rolled back when either filesystem replace failed, but it deleted the backups before the final installed-pair provenance verification. If that final verification failed, `adopt()` returned an error while leaving the newly installed pair in the project root.

V204 moves the transaction commit point behind final provenance verification. Backups are retained until the installed `pubspec.lock` + `lockfile-provenance.txt` pair verifies successfully. A post-install verification failure now rolls both destinations back to their exact prior state, or removes both on a first-ever adoption. Rollback filesystem errors are reported cleanly instead of escaping as raw exceptions.

## Regression coverage
Two new tests force the post-install verifier to fail and prove rollback for both an existing pair and a first-ever adoption, including temp-file cleanup.

## Verification status
Offline Python/static gates are run in this environment. Flutter/Dart/Xcode/Simulator/physical-device/archive verification remains NOT RUN unless explicitly reported otherwise.
