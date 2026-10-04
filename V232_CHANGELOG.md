# V232

- Added a stateful streaming adapter around the v230 transient detector.
- Incomplete PCM tails are retained across microphone callbacks, preventing silent sample loss at callback boundaries.
- Audio stream discontinuities and sample-rate changes now fail closed instead of corrupting event timing.
- Added Dart regression tests for split transients, gaps, and sample-rate changes plus an offline Python source-contract regression test.
- No claim of Flutter compilation, iOS build, Simulator, microphone hardware, or physical-device validation.
