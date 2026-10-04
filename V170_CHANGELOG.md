# V170 — iOS runtime smoke coverage hardening

- Extended `integration_test/app_launch_test.dart` to open the production **Profiller** route on a clean install, in addition to Katalog and Ayarlar.
- The smoke test now verifies the home screen keeps Balistik/DOPE fail-closed when no active profile exists.
- Added `tools/test_ios_integration_smoke_contract.py` so offline CI prevents accidental removal of these runtime smoke assertions.
- No Flutter/Xcode/Simulator execution is claimed in this environment; those gates remain for macOS CI/device validation.
