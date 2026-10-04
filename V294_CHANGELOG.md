# V294

- Fixed the active manual catalog editor so ammunition type is constrained by platform.
- Firearm manual/custom ammunition can only persist as `bullet`.
- PCP manual/custom ammunition can only persist as `pellet` or `slug`.
- Changing platform resets the ammunition type to a valid default and the persisted payload is normalized again before write, preventing stale UI state from crossing the platform boundary.
- Added a source regression test for the platform/type gate.
- No claim of Flutter runtime/analyze/test verification: Flutter SDK is unavailable in this environment.
