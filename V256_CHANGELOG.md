# V256
- Chronograph microphone capture now has an explicit cancellation path that resolves an active capture as rejected instead of leaving its Future pending.
- ChronographScreen now observes app lifecycle and cancels microphone capture whenever the app leaves the foreground (inactive/paused/hidden/detached).
- Dispose also cancels an active microphone capture with a distinct provenance/error code.
- Added 3 production regression tests for microphone lifecycle/privacy behavior.
- Full offline Python production suite: 339/339 PASS.
- Offline Dart source lint: 78 files, 0 issues.
- Python compileall: PASS.
- Flutter/iOS build, Simulator and physical iPhone tests were not run and are not claimed.
