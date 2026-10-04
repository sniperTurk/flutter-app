# V227 — Persistent measurement sessions

- Added fail-closed `MeasurementCodec` for chronograph sessions/readings and Sight Height measurements.
- Added `PersistentMeasurementStore` backed by SharedPreferences with schema versioning, backup-before-write and backup recovery behavior.
- Chronograph UI can now persist the current manual/reference session using active profile rifle/ammunition/pressure provenance.
- Sight Height UI now requires explicit perspective validation and user confirmation before a calculated value can be persisted.
- Added Dart codec regression tests. Flutter SDK is unavailable in this environment, so those Flutter tests were authored but not executed.
- Verified dependency-free Dart source hygiene: 66 Dart files, 0 issues.
- Verified complete offline Python regression suite: 274 tests passed.
- Real Flutter analyze/test, iOS build, Simulator and physical iPhone tests remain unverified.
