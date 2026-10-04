# V277

- App Store source preflight now rejects a symlinked top-level `ios/` scaffold.
- This closes an ancestor-symlink gap where regular-looking required leaf files could be reached through an external substituted iOS tree.
- Added regression coverage for the substituted iOS-directory case.
- This does not claim a real Flutter/iOS build, Simulator run, device test, signing, archive, or App Store submission.
