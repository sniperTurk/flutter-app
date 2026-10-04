# V234

- Added the missing production orchestration layer from native PCM -> streaming transient detector -> acoustic physics -> chronograph reading.
- Microphone-derived readings are structurally prevented from becoming `valid`; successful acoustic estimates are `estimated` with `ACOUSTIC_UNVALIDATED` until reference validation exists.
- Added fail-closed results for malformed PCM, stream errors, physics rejection and timeout.
- Added a Dart regression test and offline Python contract tests. Flutter execution remains unverified where the Flutter SDK is unavailable.
