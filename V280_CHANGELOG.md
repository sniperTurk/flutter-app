# V280

- Hardened `tools/bootstrap_reference_validator.py` acceptance-policy loading to fail closed on missing, malformed JSON, invalid UTF-8, and non-object policy roots instead of exposing raw parser/I/O tracebacks.
- Added `tools/test_v280_bootstrap_policy_fail_closed.py` with four regression tests.
- Full Python tools suite passes after the change.
- Flutter 3.47.2 installation was attempted to unblock `pubspec.lock` and iOS scaffold generation, but this runtime could not resolve the official Flutter storage host; no Flutter/iOS success is claimed.
