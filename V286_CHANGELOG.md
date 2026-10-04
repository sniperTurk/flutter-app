# V286

- `tools/install_pinned_flutter.py`: tar extraction now passes `filter="fully_trusted"` explicitly after the existing fail-closed member validation. This prevents Python 3.14+ tarfile default-filter changes from silently changing extraction behavior and removes the deprecation warning observed on the current runtime.
- `tools/test_install_pinned_flutter.py`: added regression coverage proving the extraction filter is explicit.
- Validation: full offline Python suite 344/344 passed; offline Dart lint passed for 58 Dart files; `python3 -m compileall -q tools` passed.
- Real Flutter/iOS validation remains blocked in this environment because the official Flutter archive could not be reached (DNS/name resolution failure). No Flutter analyze/test, iOS build, Simulator, or physical-device success is claimed.
