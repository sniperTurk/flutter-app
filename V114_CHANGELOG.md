# V114 Changelog

- Home active-profile reconciliation is now fail-soft: if profiles load but a stale active-profile pointer cannot be repaired in persistent storage, the app keeps the resolved valid profile usable for the current session instead of replacing the entire Home screen with a fatal profile-load error.
- Added a visible, live-region accessibility warning for the degraded persistence state.
- Added a Flutter widget regression test covering failed stale active-id repair while valid profiles remain available.
- Production G1/G7 gate remains closed; no unvalidated aerodynamic result was enabled.
- Flutter/Dart/Xcode were unavailable in this execution environment, so the new Flutter test, flutter analyze/test, and iOS build/simulator/device status are not claimed as passing.
