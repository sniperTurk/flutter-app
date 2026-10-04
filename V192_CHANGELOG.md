# V192 — Physical iPhone dependency-lock integrity gate

- Continued directly from V191; no project restart.
- Fixed a production integrity gap in `tools/run_physical_iphone_test.sh`: the harness previously required `pubspec.lock` to exist, but `flutter pub get` could rewrite it and the physical-device test would continue against a different dependency graph.
- The harness now hashes `pubspec.lock` immediately before and after `flutter pub get` and fails closed if the resolver changes it. The physical-iPhone PASS marker is unreachable in that case.
- Added regression coverage for the lockfile hash gate and its ordering before the hardware integration test/PASS marker.
- This Linux environment still cannot run Flutter/Xcode/Simulator/physical-iPhone verification; those gates remain NOT RUN / NOT VERIFIED.
