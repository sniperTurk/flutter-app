# V229

- Added a hardware-independent acoustic chronograph physics core for shooter-position two-event timing.
- Correctly subtracts target-to-phone sound return time before calculating projectile average flight velocity.
- Added temperature-adjusted dry-air speed-of-sound approximation and fail-closed validation for impossible timing/environment inputs.
- Added Flutter unit tests and offline regression assertions.
- This is deliberately labelled an average-velocity estimate; it is not presented as muzzle velocity.
- No microphone capture, Flutter runtime, iOS build, Simulator, or physical-device validation is claimed in this revision.
