# V174 — deterministic clean-install iOS smoke gate

## Production change
- iOS CI now removes any existing `com.sniperturk.sniperTurk` simulator app container before the raw Runner launch smoke check.
- After the raw `.app` launch succeeds, CI strictly uninstalls it again before `flutter test integration_test/app_launch_test.dart`.
- The built Runner bundle identifier must exactly match the release identity before install/launch.
- Added `tools/test_ios_ci_clean_install_smoke_wiring.py` to lock ordering and bundle-identity checks.

## Why
V173's integration test intentionally assumes a clean install and creates the first persisted profile. `simctl install` alone does not establish that previous application data is absent. A retained SharedPreferences container could therefore make reruns non-deterministic. V174 makes clean-install state an explicit fail-closed CI contract.

## Verification boundary
Offline Python/static gates can be verified without Flutter/Xcode. Real macOS Flutter, Xcode, Simulator, physical-device, signing and App Store Connect results remain unverified until run in those environments.
