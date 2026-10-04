# V254
- SpiritLevelScreen now observes iOS/Flutter lifecycle.
- Accelerometer subscription stops while app is inactive/paused/detached/hidden and restarts on resume.
- Restart is idempotent to prevent duplicate sensor subscriptions.
- Observer/subscription cleanup is explicit on dispose.
- Added 3 lifecycle regression guards; full offline suite: 333/333 PASS.
- No Flutter/iOS build, Simulator, or physical iPhone result is claimed by this change.
