# V191 — Physical iPhone production test harness

- Continued directly from V190; no project restart.
- Added a fail-closed physical-iOS device selector for `flutter devices --machine` output. Simulators can never satisfy the physical-device gate.
- Added `tools/run_physical_iphone_test.sh`, which requires macOS, Flutter, Xcode/devicectl, a committed lockfile, a real connected iOS device, the pinned Flutter toolchain, and then runs the existing integration smoke suite on that hardware.
- The harness deliberately leaves signing/provisioning failures as failures and emits a PASS marker only after the integration test succeeds on the selected physical device.
- Added regression coverage for physical-device selection and harness wiring.
- This environment is not macOS and has no connected iPhone; therefore the physical iPhone test remains NOT RUN / NOT VERIFIED. The change adds the real-device gate, not a fabricated result.
