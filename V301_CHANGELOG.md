# V301 — deterministic iOS scaffold refresh

- Fixed a release-bootstrap gap in `tools/bootstrap_ios_scaffold.sh`: the script no longer skips `flutter create --platforms=ios ...` merely because an `ios/` directory already exists.
- The pinned Flutter toolchain now refreshes/generates the iOS scaffold on every bootstrap run before SNIPER TÜRK-specific Info.plist and privacy-manifest wiring is applied.
- Added `tools/test_v301_ios_scaffold_refresh.py` to lock the refresh contract and verify CI still invokes scaffold bootstrap before the Simulator build.
- This change does **not** claim an iOS build passed. The current environment could not install Flutter 3.47.2 because outbound DNS/network access failed, so Flutter analyze/test, resolver lockfile generation, iOS build, Simulator and physical-device validation remain unverified.
