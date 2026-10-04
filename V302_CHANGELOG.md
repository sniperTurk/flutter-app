# V302 — clean iOS scaffold regeneration

- Corrected the v301 release-bootstrap assumption that running `flutter create` over an existing `ios/` tree guarantees a clean refresh.
- `tools/bootstrap_ios_scaffold.sh` now rejects a symlinked `ios` path, removes a real pre-existing iOS tree, and regenerates it from the pinned Flutter toolchain before applying SNIPER TÜRK metadata/privacy wiring.
- Added `tools/test_v302_clean_ios_scaffold.py` to lock ordering and symlink-safety contracts.
- This does not claim Flutter/iOS execution passed; Flutter/Dart SDK is unavailable in the current environment.
