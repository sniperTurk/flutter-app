# V279 — App Store preflight corrupted-input regression

Based on accessible v278 source. Added eight regression tests for malformed/missing release inputs and hardened App Store preflight to fail closed on invalid UTF-8, invalid Info.plist XML, and unreadable Dart capability-scan inputs. Avoids hashing missing or symlinked pubspec and avoids duplicate scaffold-absent message for a symlinked ios tree.

Verified in this runtime: `python3 -m unittest discover -s tools -p 'test_*.py'`: 325 tests passed. `python3 -m unittest tools.test_v279_preflight_fail_closed_inputs`: 8 passed. No Flutter/iOS build or device test.
