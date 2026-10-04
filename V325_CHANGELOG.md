# V325 Changelog

- Merged the v324_fixed App Store export path-safety fixes with the previously verified Flutter SDK transactional rollback fix.
- `tools/claude_bootstrap_and_verify.sh` now preserves a verified existing official Flutter checkout until the Google archive fallback succeeds; failed fallback restores the previous SDK.
- Restored `tools/test_v324_flutter_bootstrap_update_rollback.py` so this data-loss regression remains covered alongside the v324_fixed export regression coverage.
- No claim of Flutter/Xcode/iOS runtime verification is made in this environment.
