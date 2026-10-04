# V253

- Continued from V252; no project reset.
- Improved the production spirit-level signal path: accelerometer gravity samples now use a low-pass filter before roll/pitch calculation and calibration, reducing single-sample jitter on the 0.01° display.
- Non-finite accelerometer samples are rejected instead of entering angle/painter state.
- Kept the UI disclosure explicit: 0.01° is display resolution, not a physical sensor-accuracy claim.
- Added production regression guards for filtering, invalid-sample handling, and the accuracy disclosure.
- Attempted the independent G1/G7 validator bootstrap, but network/DNS access was unavailable; no reference fixture was generated and the production ballistic gate remains correctly closed.
- No claim is made for Flutter compile, iOS build, Simulator, or physical iPhone validation.
