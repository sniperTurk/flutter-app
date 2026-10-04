# V321 — signed export cleanup confinement

- Hardened `tools/export_signed_app_store_ipa.sh` before its destructive export-directory cleanup.
- Canonicalizes the requested export directory and permits cleanup only below the project-owned `build/ios/` tree.
- Rejects an export target that resolves outside that tree or is itself a symlink.
- Added `tools/test_v321_signed_export_path_safety.py`.
- Regression was demonstrated red on v320 before the fix and green after the fix.
- No real Xcode signing/export is claimed in this environment.
