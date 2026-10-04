# V209 CHANGELOG

- Continued directly from verified V208.
- Closed a local release-verification gap in `tools/claude_flutter_verify.sh`.
- The existing-lockfile path now re-runs `verify_lockfile_provenance.py` after `flutter pub get` proves the lockfile did not drift.
- This prevents local verification from accepting a stable but stale/hand-edited/wrong-toolchain lockfile + provenance pair while iOS CI would reject it.
- Added a regression contract proving both bootstrap and existing-lockfile paths verify provenance before formatting/analyze/test gates.
- No claim of real Flutter/Xcode execution is made by this release.
