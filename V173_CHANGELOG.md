# V173 — iOS clean-install profile persistence smoke coverage

## What changed
- Extended `integration_test/app_launch_test.dart` beyond read-only navigation.
- The production iOS smoke path now creates a profile through the real editor, persists it through `SharedPreferences`, returns Home, verifies first-profile active reconciliation, and opens the real Balistik/DOPE route.
- Added `tools/test_ios_profile_persistence_smoke_contract.py` so the end-to-end persistence/DOPE coverage cannot silently disappear from CI.

## Why
The prior smoke test proved launch and route navigation but never wrote user data. Profile persistence and the transition from no-profile fail-closed state to an active ballistic profile are release-critical runtime paths. This change makes CI exercise that path when a real iOS Simulator is available.

## Verification boundary
Offline/static regression tests can verify the smoke contract is wired. They do **not** prove the Flutter integration test passes on iOS. Real iOS success remains unverified until the macOS CI/Simulator job actually runs.
