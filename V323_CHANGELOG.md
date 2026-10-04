# V323 changelog

- Hardened `tools/export_signed_app_store_ipa.sh` against archive-path substitution.
- The signed App Store export gate now canonicalizes the supplied `.xcarchive` and rejects symlink archives or archives resolving outside `build/ios/archive` before invoking signing-state verification or `xcodebuild`.
- Added `tools/test_v323_signed_export_archive_path_safety.py`; it reproduces the v322 fail-open behavior with an out-of-tree archive symlink and locks the new fail-closed contract.
- No claim of a real iOS build, Simulator run, physical-device run, or signed export is made; those still require Flutter/Xcode/macOS/Apple signing assets.
