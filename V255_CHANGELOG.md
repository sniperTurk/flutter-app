# V255
- CompassScreen now observes Flutter/iOS lifecycle, stopping its compass stream while inactive/backgrounded and restarting on resume.
- Compass stream start is idempotent, preventing duplicate subscriptions across repeated resume events.
- Transient null/non-finite compass samples no longer erase the last valid bearing; the UI reports a calibration/read warning instead.
- Added 3 compass lifecycle/data-integrity regression guards.
- No Flutter/iOS build, Simulator, or physical iPhone result is claimed by this change.

- Full offline Python production suite after this change: 336/336 PASS.
- Offline Dart source lint: 78 files, 0 issues.
