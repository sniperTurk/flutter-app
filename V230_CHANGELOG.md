# V230

- Added a hardware-independent normalized PCM transient detector for chronograph audio.
- Added adaptive noise-floor thresholding, a refractory interval, absolute sample timestamps, and fail-closed PCM/sample-rate validation.
- Added `ChronographAudioSource` as the explicit platform microphone boundary; no microphone implementation is claimed in this version.
- Added Flutter unit tests for transient/noise/invalid-input behavior and an offline source-contract regression test.
- Real microphone capture, Flutter runtime tests, iOS build, Simulator, and physical iPhone validation remain unverified.
