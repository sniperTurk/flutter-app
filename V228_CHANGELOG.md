# V228 — Chronograph persistence UI completion

- Fixed a production wiring defect in `ChronographScreen`: the existing `_saveSession()` persistence path was unreachable because no save control invoked it.
- Added a visible **Oturumu kaydet** action after valid readings exist.
- Added single-flight save state so repeated taps cannot enqueue duplicate writes while a save is in progress.
- Added visible success/failure feedback; failed saves keep current readings on screen.
- A successful save clears the in-memory readings so the next readings form a fresh session rather than silently duplicating the just-persisted session.
- Added offline regression coverage for save-action reachability, feedback, single-flight behavior, and successful-session reset.
- No microphone/camera/Qwen capability is claimed by this change.
