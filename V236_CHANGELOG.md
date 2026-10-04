# V236 changelog

- Added explicit chronograph measurement provenance (`manualReference` vs `acousticMicrophone`).
- Acoustic capture now persists target distance and temperature used by the estimator.
- Measurement codec remains backward compatible: pre-v236 readings without a source decode as manual/reference readings.
- Codec fails closed if an acoustic microphone reading is ever encoded or decoded as `valid`; unvalidated microphone output remains `estimated`.
- Added Dart codec regression cases and Python production-contract tests.
- No claim of Flutter/iOS compilation or physical-device validation is made.
