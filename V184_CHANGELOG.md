# V184 — app-owned iOS privacy manifest source + Runner target wiring

## Changed
- Added a canonical app-owned `release/ios/PrivacyInfo.xcprivacy`.
- Declares `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`, matching the existing archive gate and Apple's required-reason manifest structure.
- Added `tools/configure_ios_privacy_manifest.rb` to copy the canonical manifest into generated `ios/Runner/` and add it to the Runner target Copy Bundle Resources phase.
- `bootstrap_ios_scaffold.sh` now fails closed if Ruby/xcodeproj is unavailable or the Runner manifest cannot be installed.
- Added regression tests tying the canonical manifest, bootstrap wiring, and strict archive gate together.

## Why
V183 correctly required `Runner.app/PrivacyInfo.xcprivacy` in the built archive but did not create/wire an app-owned manifest. A real macOS CI run could therefore be guaranteed to stop at the strict archive privacy gate even when plugin manifests were valid. V184 supplies the missing source-side production artifact and deterministic target wiring.

## Still not claimed
`dart format`, `flutter analyze`, `flutter test`, Xcode build, Simulator/integration test, real xcarchive, signing, TestFlight and physical-iPhone validation were not run in this environment.
